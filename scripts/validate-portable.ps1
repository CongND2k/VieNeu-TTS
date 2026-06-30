# Validate VieNeu-TTS portable package layout (run on Windows after build).
param(
    [string]$DistDir = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not $DistDir) {
    $DistDir = Join-Path $Root "dist\VieNeu-TTS-Portable"
}

$checks = @(
    @{ Path = "Start.bat"; Label = "Launcher" },
    @{ Path = "Download-Models.bat"; Label = "Model downloader" },
    @{ Path = "hf_cache_env.bat"; Label = "HF cache config" },
    @{ Path = "download_portable_models.py"; Label = "Download script" },
    @{ Path = "Chuyen-May-Khac.bat"; Label = "Transfer guide" },
    @{ Path = "README.txt"; Label = "Readme" },
    @{ Path = "app\apps\gradio_main.py"; Label = "Gradio app" },
    @{ Path = "app\src\vieneu\__init__.py"; Label = "vieneu package" },
    @{ Path = "app\config.yaml"; Label = "Config" },
    @{ Path = "runtime\python\Scripts\python.exe"; Label = "Python runtime" },
    @{ Path = "runtime\cache\huggingface"; Label = "HF cache dir" }
)

Write-Host "== Validating portable package =="
Write-Host "Path: $DistDir"
Write-Host ""

$failed = 0
foreach ($check in $checks) {
    $full = Join-Path $DistDir $check.Path
    if (Test-Path $full) {
        Write-Host "[OK]   $($check.Label): $($check.Path)"
    } else {
        Write-Host "[FAIL] $($check.Label): $($check.Path)"
        $failed++
    }
}

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Validation failed ($failed missing items)."
    exit 1
}

Write-Host ""
Write-Host "Layout validation passed."
Write-Host "Manual test checklist:"
Write-Host "  [ ] Double-click Start.bat on a machine without Python installed"
Write-Host "  [ ] Web UI opens at http://127.0.0.1:7860"
Write-Host "  [ ] TTS works with default voice (offline, no internet)"
Write-Host "  [ ] Copy folder to another drive/USB and run again"
