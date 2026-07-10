# Run release candidate verification gates.
param(
    [switch]$SkipAndroid,
    [switch]$RequireStoreSigning
)

$ErrorActionPreference = "Stop"
$ProjectDir = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectDir
$PowerShellExe = (Get-Process -Id $PID).Path

function Invoke-Step {
    param(
        [string]$Name,
        [string[]]$Command
    )

    Write-Host ""
    Write-Host "==> $Name" -ForegroundColor Cyan
    $cmd, $cmdArgs = $Command
    & $cmd @cmdArgs
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

function Read-Properties {
    param([string]$Path)

    $result = @{}
    Get-Content -Path $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith("#")) {
            return
        }

        $parts = $line.Split("=", 2)
        if ($parts.Length -eq 2) {
            $result[$parts[0].Trim()] = $parts[1].Trim()
        }
    }

    return $result
}

function Test-StoreSigning {
    $appDir = Join-Path (Join-Path $ProjectDir "android") "app"
    $propsPath = Join-Path $appDir "keystore.properties"
    if (-not (Test-Path -LiteralPath $propsPath)) {
        throw "Missing android/app/keystore.properties. Run scripts/generate_keystore.ps1 or copy android/app/keystore.properties.example."
    }

    $props = Read-Properties -Path $propsPath
    foreach ($key in @("storeFile", "storePassword", "keyAlias")) {
        if (-not $props.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($props[$key])) {
            throw "android/app/keystore.properties is missing $key."
        }
    }

    if (-not $props.ContainsKey("keyPassword") -or [string]::IsNullOrWhiteSpace($props["keyPassword"])) {
        Write-Host "keyPassword is not set; Gradle will use storePassword for the key password." -ForegroundColor Yellow
    }

    $storeFile = $props["storeFile"]
    $storePath = $storeFile
    if (-not [System.IO.Path]::IsPathRooted($storePath)) {
        $storePath = Join-Path $appDir $storeFile
    }

    if (-not (Test-Path -LiteralPath $storePath)) {
        throw "Keystore file does not exist: $storePath"
    }

    Write-Host "Android store signing files are present." -ForegroundColor Green
}

try {
    if ($RequireStoreSigning) {
        Test-StoreSigning
    }

    Invoke-Step "Content data verification" @($PowerShellExe, "-ExecutionPolicy", "Bypass", "-File", "scripts/verify_content.ps1")
    Invoke-Step "Flutter pub get" @("flutter", "pub", "get")
    Invoke-Step "Dart analyze" @("flutter", "analyze")
    Invoke-Step "Flutter test" @("flutter", "test")
    Invoke-Step "Flutter web release build" @("flutter", "build", "web", "--no-web-resources-cdn")

    if (-not $SkipAndroid) {
        Invoke-Step "Flutter Android APK release build" @("flutter", "build", "apk", "--release")
        Invoke-Step "Flutter Android App Bundle release build" @("flutter", "build", "appbundle", "--release")
    }

    Write-Host ""
    Write-Host "Release verification completed successfully." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Release verification failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
