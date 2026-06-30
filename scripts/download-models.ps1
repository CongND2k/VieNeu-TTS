# Download HuggingFace models for offline VieNeu-TTS portable build.
param(
    [string]$CacheDir = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not $CacheDir) {
    $PortableCache = Join-Path $Root "dist\VieNeu-TTS-Portable\runtime\cache\huggingface"
    if (Test-Path (Split-Path $PortableCache -Parent)) {
        $CacheDir = $PortableCache
    } else {
        $CacheDir = Join-Path $env:LOCALAPPDATA "VieNeu-TTS\hf-cache"
    }
}

$env:HF_HOME = $CacheDir
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null

Write-Host ">> HF_HOME = $CacheDir"

function Ensure-Uv {
    if (Get-Command uv -ErrorAction SilentlyContinue) { return }
    Write-Host ">> Installing uv..."
    irm https://astral.sh/uv/install.ps1 | iex
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

Ensure-Uv
uv sync --quiet

$downloadScriptPath = Join-Path $Root "dist-templates\download_portable_models.py"
if (-not (Test-Path $downloadScriptPath)) {
    throw "Missing dist-templates\download_portable_models.py"
}

Write-Host ">> Downloading models..."
$env:HF_HOME = $CacheDir
uv run python $downloadScriptPath

$totalBytes = (Get-ChildItem -Recurse $CacheDir -File -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum
if ($totalBytes) {
    Write-Host ("   Cache size: {0:N2} MB" -f ($totalBytes / 1MB))
}
