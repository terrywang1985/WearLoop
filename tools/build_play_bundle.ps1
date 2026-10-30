param(
    [string]$KeyProperties = (Join-Path $env:LOCALAPPDATA 'WearLoop\Signing\key.properties'),
    [string]$SupportEmail,
    [string]$PrivacyPolicyUrl,
    [string]$BuildNumber = '4'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $KeyProperties)) { throw 'An owner-managed upload signing configuration is required.' }
if ($SupportEmail -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Provide the approved public support email with -SupportEmail.' }
$taskPolicyUri = $null
if (-not [Uri]::TryCreate($PrivacyPolicyUrl, [UriKind]::Absolute, [ref]$taskPolicyUri) -or $taskPolicyUri.Scheme -ne 'https') {
    throw 'Provide the public HTTPS privacy policy URL with -PrivacyPolicyUrl.'
}
$taskAppRoot = Split-Path -Parent $PSScriptRoot
$taskFlutterRoot = Join-Path $env:USERPROFILE '.codex\runtimes\flutter-3.47.8'
$taskFlutter = Join-Path $taskFlutterRoot 'bin\flutter.bat'
if (-not (Test-Path -LiteralPath $taskFlutter)) { throw 'The validated Flutter runtime was not found.' }
$env:WEARLOOP_KEY_PROPERTIES = [IO.Path]::GetFullPath($KeyProperties)
$env:PATH = (Join-Path $taskFlutterRoot 'bin') + ';' + (Join-Path $env:APPDATA 'Python\Python314\Scripts') + ';' + $env:PATH
Push-Location $taskAppRoot
try {
    & $taskFlutter build appbundle --release --no-pub "--build-number=$BuildNumber" `
        "--dart-define=WEARLOOP_SUPPORT_EMAIL=$SupportEmail" `
        "--dart-define=WEARLOOP_PRIVACY_URL=$PrivacyPolicyUrl"
    if ($LASTEXITCODE -ne 0) { throw 'Google Play app bundle build failed.' }
    $taskBundlePath = Join-Path $taskAppRoot 'build\app\outputs\bundle\release\app-release.aab'
    if (-not (Test-Path -LiteralPath $taskBundlePath)) { throw 'Build reported success without an app bundle.' }
    & python (Join-Path $PSScriptRoot 'audit_android_artifact.py') $taskBundlePath `
        --output (Join-Path $taskAppRoot 'docs\google-play\aab-technical-evidence.json')
    if ($LASTEXITCODE -ne 0) { throw 'Bundle native-library audit failed.' }
    $taskBundleItem = Get-Item -LiteralPath $taskBundlePath
    [PSCustomObject]@{
        path = $taskBundlePath
        bytes = $taskBundleItem.Length
        sha256 = (Get-FileHash -LiteralPath $taskBundlePath -Algorithm SHA256).Hash.ToLowerInvariant()
        buildNumber = $BuildNumber
        supportEmail = $SupportEmail
        privacyPolicyUrl = $PrivacyPolicyUrl
        submittedToGooglePlay = $false
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $taskAppRoot 'docs\google-play\bundle-build.json') -Encoding utf8
    Write-Output "Built signed review candidate: $taskBundlePath"
    Write-Output 'A successful build does not establish model rights or complete Console declarations. Review those before uploading.'
} finally {
    Pop-Location
}
