param(
    [string]$SigningDirectory = (Join-Path $env:LOCALAPPDATA 'WearLoop\Signing'),
    [string]$Keytool = 'keytool.exe'
)

$ErrorActionPreference = 'Stop'
$taskSigningPath = [IO.Path]::GetFullPath($SigningDirectory)
$taskStorePath = Join-Path $taskSigningPath 'wearloop-upload.jks'
$taskPropertiesPath = Join-Path $taskSigningPath 'key.properties'
$taskCertificatePath = Join-Path $taskSigningPath 'wearloop-upload-certificate.pem'
if ((Test-Path -LiteralPath $taskStorePath) -or (Test-Path -LiteralPath $taskPropertiesPath)) {
    if ((Test-Path -LiteralPath $taskStorePath) -and (Test-Path -LiteralPath $taskPropertiesPath)) {
        Write-Output "Existing signing files retained: $taskSigningPath"
        exit 0
    }
    throw 'Partial signing configuration exists; inspect it before continuing. No file was overwritten.'
}

New-Item -ItemType Directory -Path $taskSigningPath -Force | Out-Null
$taskIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$taskAcl = [Security.AccessControl.DirectorySecurity]::new()
$taskAcl.SetOwner($taskIdentity.User)
$taskAcl.SetAccessRuleProtection($true, $false)
$taskInheritance = [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit'
foreach ($taskSid in @($taskIdentity.User, [Security.Principal.SecurityIdentifier]::new('S-1-5-18'))) {
    $taskRule = [Security.AccessControl.FileSystemAccessRule]::new(
        $taskSid, 'FullControl', $taskInheritance,
        [Security.AccessControl.PropagationFlags]::None,
        [Security.AccessControl.AccessControlType]::Allow
    )
    $taskAcl.AddAccessRule($taskRule)
}
Set-Acl -LiteralPath $taskSigningPath -AclObject $taskAcl

$taskSecret = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(48))
$taskSecretPath = Join-Path $taskSigningPath 'creation-password.tmp'
$taskUtf8 = [Text.UTF8Encoding]::new($false)
try {
    [IO.File]::WriteAllText($taskSecretPath, $taskSecret, $taskUtf8)
    & $Keytool -genkeypair -keystore $taskStorePath -storetype JKS -alias wearloop-upload `
        -keyalg RSA -keysize 4096 -validity 10000 `
        -dname 'CN=WearLoop Upload, OU=Release, O=WearLoop' `
        '-storepass:file' $taskSecretPath '-keypass:file' $taskSecretPath
    if ($LASTEXITCODE -ne 0) { throw 'Upload key generation failed.' }
    $taskStoreProperty = $taskStorePath.Replace('\', '/')
    $taskPropertyContent = "storeFile=$taskStoreProperty`nstorePassword=$taskSecret`nkeyAlias=wearloop-upload`nkeyPassword=$taskSecret`n"
    [IO.File]::WriteAllText($taskPropertiesPath, $taskPropertyContent, $taskUtf8)
    & $Keytool -exportcert -rfc -keystore $taskStorePath -alias wearloop-upload `
        '-storepass:file' $taskSecretPath -file $taskCertificatePath
    if ($LASTEXITCODE -ne 0) { throw 'Public upload certificate export failed.' }
    Write-Output "Private signing files created outside project: $taskSigningPath"
    Write-Output "Build variable WEARLOOP_KEY_PROPERTIES: $taskPropertiesPath"
    Write-Output 'Keep the private keystore and properties together in a secure owner-managed backup. Never upload them to Play Console.'
} finally {
    if (Test-Path -LiteralPath $taskSecretPath) { Remove-Item -LiteralPath $taskSecretPath }
    $taskSecret = $null
    $taskPropertyContent = $null
}
