# Build VieNeu-TTS portable Windows package (zero-install).
# Run on Windows or GitHub Actions windows-latest.
param(
    [switch]$SkipModels
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$DistName = "VieNeu-TTS-Portable"
$DistDir = Join-Path $Root "dist\$DistName"
$ZipPath = Join-Path $Root "dist\VieNeu-TTS-Portable-win64.zip"
$RuntimePython = Join-Path $DistDir "runtime\python"
$RuntimeCache = Join-Path $DistDir "runtime\cache\huggingface"
$AppDir = Join-Path $DistDir "app"

function Ensure-Uv {
    if (Get-Command uv -ErrorAction SilentlyContinue) { return }
    Write-Host ">> Installing uv..."
    irm https://astral.sh/uv/install.ps1 | iex
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
    if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
        throw "uv installation failed"
    }
}

Write-Host "== VieNeu-TTS Portable Build =="
Write-Host "Root: $Root"

Ensure-Uv

Write-Host ">> Installing dependencies (CPU/ONNX, no GPU)..."
uv sync

Write-Host ">> Installing vieneu into venv (non-editable, portable)..."
uv pip install --no-deps --force-reinstall --no-editable .

if (-not $SkipModels) {
    Write-Host ">> Downloading offline models..."
    & (Join-Path $Root "scripts\download-models.ps1") -CacheDir $RuntimeCache
} else {
    Write-Host ">> Skipping model download (--SkipModels)"
    New-Item -ItemType Directory -Force -Path $RuntimeCache | Out-Null
}

Write-Host ">> Preparing dist folder..."
if (Test-Path $DistDir) { Remove-Item -Recurse -Force $DistDir }
New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $RuntimePython) | Out-Null

Write-Host ">> Copying application source..."
$CopyItems = @("apps", "src", "config.yaml", "pyproject.toml", "uv.lock", "LICENSE")
foreach ($item in $CopyItems) {
    $src = Join-Path $Root $item
    if (Test-Path $src) {
        Copy-Item -Recurse -Force $src (Join-Path $AppDir $item)
    }
}

Write-Host ">> Copying Python runtime (.venv)..."
$VenvSrc = Join-Path $Root ".venv"
if (-not (Test-Path $VenvSrc)) {
    throw ".venv not found. Run 'uv sync' first."
}
Copy-Item -Recurse -Force $VenvSrc $RuntimePython

# Fix pyvenv.cfg for portable use (relative home path).
$PyvenvCfg = Join-Path $RuntimePython "pyvenv.cfg"
if (Test-Path $PyvenvCfg) {
    $cfg = Get-Content $PyvenvCfg
    $cfg = $cfg | ForEach-Object {
        if ($_ -match '^home\s*=') { "home = ." } else { $_ }
    }
    Set-Content -Path $PyvenvCfg -Value $cfg -Encoding UTF8
}

Write-Host ">> Copying launcher..."
$StartTemplate = Join-Path $Root "dist-templates\Start.bat"
if (-not (Test-Path $StartTemplate)) {
    throw "Missing dist-templates\Start.bat"
}
Copy-Item -Force $StartTemplate (Join-Path $DistDir "Start.bat")

$DownloadModelsTemplate = Join-Path $Root "dist-templates\Download-Models.bat"
if (Test-Path $DownloadModelsTemplate) {
    Copy-Item -Force $DownloadModelsTemplate (Join-Path $DistDir "Download-Models.bat")
}

$Readme = @"
VieNeu-TTS Portable (Windows)
=============================

Cach chay:
  1. Double-click Start.bat
  2. Trinh duyet se mo http://127.0.0.1:7860
  3. Chon model "VieNeu-TTS-v3-Turbo" va tao giong noi

Yeu cau:
  - Windows 10/11 x64
  - Khong can cai Python, uv, hay internet (offline)

Port mac dinh: 7860
Doi port: sua GRADIO_SERVER_PORT trong Start.bat

Thu muc:
  app/              - ma nguon ung dung
  runtime/python/   - Python + thu vien
  runtime/cache/    - model da tai san

"@ 
Set-Content -Path (Join-Path $DistDir "README.txt") -Value $Readme -Encoding UTF8

Write-Host ">> Creating ZIP archive..."
if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
New-Item -ItemType Directory -Force -Path (Split-Path $ZipPath) | Out-Null
Compress-Archive -Path $DistDir -DestinationPath $ZipPath -CompressionLevel Optimal

Write-Host ">> Validating portable layout..."
& (Join-Path $Root "scripts\validate-portable.ps1") -DistDir $DistDir

Write-Host ""
Write-Host "== Build complete =="
Write-Host "Folder: $DistDir"
Write-Host "ZIP:    $ZipPath"
$zipSize = (Get-Item $ZipPath).Length / 1GB
Write-Host ("Size:   {0:N2} GB" -f $zipSize)
Write-Host ""
Write-Host "Test on a clean Windows machine:"
Write-Host "  1. Extract ZIP"
Write-Host "  2. Double-click Start.bat"
Write-Host "  3. Verify http://127.0.0.1:7860 works offline"
