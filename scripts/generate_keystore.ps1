# Generate keystore for release signing
param(
    [string]$ProjectDir = ".."
)

$ErrorActionPreference = "Stop"
$keystoreDir = Join-Path $ProjectDir "android" "app"
$keystorePath = Join-Path $keystoreDir "keystore.jks"
$propsPath = Join-Path $keystoreDir "keystore.properties"

# Generate random passwords
$chars = @(65..90) + @(97..122) + @(48..57)  # A-Z, a-z, 0-9
$storePass = -join ($chars | Get-Random -Count 32 | ForEach-Object { [char]$_ })
$keyPass = -join ($chars | Get-Random -Count 32 | ForEach-Object { [char]$_ })

Write-Host "KEYSTORE_PASSWORD = $storePass" -ForegroundColor Yellow
Write-Host "KEY_PASSWORD      = $keyPass" -ForegroundColor Yellow

# Generate keystore
& keytool -genkeypair -v `
    -keystore $keystorePath `
    -alias heenotane `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $storePass `
    -keypass $keyPass `
    -dname "CN=HeeNoTane, OU=Development, O=HeeNoTane, L=Tokyo, ST=Tokyo, C=JP" 2>&1

Write-Host "Keystore saved to: $keystorePath" -ForegroundColor Green

# Save passwords
@"
storePassword=$storePass
keyPassword=$keyPass
keyAlias=heenotane
storeFile=keystore.jks
"@ | Set-Content -Path $propsPath -Encoding UTF8

Write-Host "Properties saved to: $propsPath" -ForegroundColor Green
Write-Host ">>> KEEP THESE FILES SECURE AND BACKED UP <<<" -ForegroundColor Red
