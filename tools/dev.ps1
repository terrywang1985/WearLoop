param(
    [string]$FlutterSdk = '',
    [string]$Device = 'web-server',
    [int]$Port = 5180
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localRuntime = Join-Path $env:USERPROFILE '.codex/runtimes/flutter-3.47.8'
if ($FlutterSdk) {
    $flutterCommand = Join-Path $FlutterSdk 'bin/flutter.bat'
} elseif (Test-Path -LiteralPath (Join-Path $localRuntime 'bin/flutter.bat')) {
    $flutterCommand = Join-Path $localRuntime 'bin/flutter.bat'
} else {
    $flutterCommand = (Get-Command flutter -ErrorAction Stop).Source
}

Push-Location $projectRoot
try {
    & $flutterCommand pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed. WearLoop requires Flutter 3.47.8 / Dart 3.13.7 or newer.' }
    $runArguments = @('run', '-d', $Device)
    if ($Device -eq 'web-server') { $runArguments += @('--web-hostname', '127.0.0.1', '--web-port', $Port, '--dart-define=WEARLOOP_PHONE_PREVIEW=true') }
    & $flutterCommand @runArguments
} finally {
    Pop-Location
}
