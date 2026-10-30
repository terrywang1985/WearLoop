$ErrorActionPreference = 'Continue'
$appRoot = Split-Path -Parent $PSScriptRoot
$log = Join-Path $appRoot 'build_android_release.log'
$status = Join-Path $appRoot 'build_android_release.status'
Set-Content -LiteralPath $log -Encoding UTF8 -Value ("Started " + (Get-Date -Format o))
Remove-Item -LiteralPath $status -ErrorAction SilentlyContinue
$sdk = Join-Path $env:USERPROFILE '.codex\runtimes\flutter-3.47.8'
$flutter = Join-Path $sdk 'bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { Set-Content -LiteralPath $status -Encoding UTF8 -Value "FAILED|Flutter 3.47.8 not found"; exit 2 }
$ninjaDir = Join-Path $env:APPDATA 'Python\Python314\Scripts'
$env:PATH = (Join-Path $sdk 'bin') + ';' + $ninjaDir + ';' + $env:PATH
Push-Location $appRoot
Add-Content -LiteralPath $log -Encoding UTF8 -Value '=== flutter --version ==='
& $flutter --version 2>&1 | Out-File -FilePath $log -Append -Encoding UTF8
if ($LASTEXITCODE -ne 0) { Set-Content -LiteralPath $status -Encoding UTF8 -Value ("FAILED|flutter --version exit " + $LASTEXITCODE); exit $LASTEXITCODE }
Add-Content -LiteralPath $log -Encoding UTF8 -Value '=== flutter clean ==='
& $flutter clean 2>&1 | Out-File -FilePath $log -Append -Encoding UTF8
if ($LASTEXITCODE -ne 0) { Set-Content -LiteralPath $status -Encoding UTF8 -Value ("FAILED|flutter clean exit " + $LASTEXITCODE); exit $LASTEXITCODE }
Add-Content -LiteralPath $log -Encoding UTF8 -Value '=== flutter pub get ==='
& $flutter pub get 2>&1 | Out-File -FilePath $log -Append -Encoding UTF8
if ($LASTEXITCODE -ne 0) { Set-Content -LiteralPath $status -Encoding UTF8 -Value ("FAILED|flutter pub get exit " + $LASTEXITCODE); exit $LASTEXITCODE }
Add-Content -LiteralPath $log -Encoding UTF8 -Value '=== flutter build apk --release ==='
& $flutter build apk --release 2>&1 | Out-File -FilePath $log -Append -Encoding UTF8
if ($LASTEXITCODE -ne 0) { Set-Content -LiteralPath $status -Encoding UTF8 -Value ("FAILED|flutter build apk exit " + $LASTEXITCODE); exit $LASTEXITCODE }
$apk = Join-Path $appRoot 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path -LiteralPath $apk)) { Set-Content -LiteralPath $status -Encoding UTF8 -Value "FAILED|APK missing after successful build"; exit 3 }
$item = Get-Item -LiteralPath $apk
$hash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $status -Encoding UTF8 -Value ("SUCCESS|{0}|{1}|{2}" -f $apk, $item.Length, $hash)
Add-Content -LiteralPath $log -Encoding UTF8 -Value ("SUCCESS " + $apk)
Pop-Location
exit 0