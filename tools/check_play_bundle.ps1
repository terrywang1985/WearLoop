param(
    [string]$Bundle = 'build/app/outputs/bundle/release/app-release.aab',
    [switch]$GenerateApks,
    [string]$JavaHome = 'D:\Program Files\Android\Android Studio\jbr'
)

$ErrorActionPreference = 'Stop'
$appRoot = Split-Path -Parent $PSScriptRoot
$bundlePath = if ([IO.Path]::IsPathRooted($Bundle)) { $Bundle } else { Join-Path $appRoot $Bundle }
if (-not (Test-Path -LiteralPath $bundlePath -PathType Leaf)) {
    throw "App bundle is missing: $bundlePath"
}
$env:JAVA_HOME = $JavaHome
$javaSigner = Join-Path $JavaHome 'bin\jarsigner.exe'
$keytool = Join-Path $JavaHome 'bin\keytool.exe'
$evidencePath = Join-Path $appRoot 'docs\google-play\aab-technical-evidence.json'
$apkSet = Join-Path $appRoot 'build\google-play-check.apks'
$aapt2 = Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools\36.0.0\aapt2.exe'

Push-Location $appRoot
try {
    & python 'tools/cached_bundletool.py' validate "--bundle=$bundlePath"
    if ($LASTEXITCODE -ne 0) { throw 'bundletool validate failed.' }
    $signatureOutput = & $javaSigner '-J-Duser.language=en' '-J-Duser.country=US' -verify $bundlePath 2>&1
    $signatureExitCode = $LASTEXITCODE
    Write-Output $signatureOutput
    # jarsigner can return exit 0 for an unsigned archive, so inspect its result.
    if ($signatureExitCode -ne 0 -or ($signatureOutput -join "`n") -notmatch '(?m)^\s*jar verified\.') {
        throw 'AAB is unsigned or JAR signature verification failed.'
    }
    $certificateOutput = & $keytool '-J-Duser.language=en' '-J-Duser.country=US' -printcert -jarfile $bundlePath 2>&1
    if ($LASTEXITCODE -ne 0 -or ($certificateOutput -join "`n") -match 'Owner:.*CN=Android Debug') {
        throw 'AAB certificate is missing or uses the Android Debug certificate.'
    }
    & python 'tools/audit_android_artifact.py' $bundlePath --output $evidencePath
    if ($LASTEXITCODE -ne 0) { throw 'AAB native static alignment check failed.' }

    if ($GenerateApks) {
        if (-not (Test-Path -LiteralPath $aapt2 -PathType Leaf)) { throw 'Installed SDK 36 aapt2 is missing.' }
        # These generated APKs are for local validation only. Bundletool uses
        # the existing Android debug key, not the private Play upload key.
        & python 'tools/cached_bundletool.py' build-apks "--bundle=$bundlePath" "--output=$apkSet" "--aapt2=$aapt2" --overwrite
        if ($LASTEXITCODE -ne 0) { throw 'Local generated APK set creation failed.' }
        & python 'tools/cached_bundletool.py' get-size total "--apks=$apkSet"
        if ($LASTEXITCODE -ne 0) { throw 'Generated APK download-size estimate failed.' }
    }
    Write-Output ('Checked bundle SHA256: ' + (Get-FileHash -LiteralPath $bundlePath -Algorithm SHA256).Hash.ToLowerInvariant())
    Write-Output "Native evidence: $evidencePath"
} finally {
    Pop-Location
}
