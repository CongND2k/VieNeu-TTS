# Download HuggingFace models for offline VieNeu-TTS portable build.
param(
    [string]$CacheDir = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not $CacheDir) {
    $CacheDir = Join-Path $Root "dist\runtime\cache\huggingface"
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

$downloadScript = @'
import os
import sys
from huggingface_hub import hf_hub_download

cache = os.environ["HF_HOME"]
os.makedirs(cache, exist_ok=True)

downloads = [
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "onnx/vieneu_prefill.onnx"),
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "onnx/vieneu_decode_step.onnx"),
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "onnx/vieneu_acoustic_cached.onnx"),
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "onnx/vieneu_backbone_shared.data"),
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "onnx/vieneu_v3_heads.npz"),
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "config.json"),
    ("pnnbao-ump/VieNeu-TTS-v3-Turbo", "tokenizer.json"),
    ("OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX", "moss_audio_tokenizer_decode_full.onnx"),
    ("OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX", "moss_audio_tokenizer_decode_shared.data"),
    ("OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX", "moss_audio_tokenizer_encode.onnx"),
    ("OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX", "moss_audio_tokenizer_encode.data"),
]

for repo, filename in downloads:
    print(f"   {repo} :: {filename}")
    hf_hub_download(repo_id=repo, filename=filename)

print(">> Model download complete.")
'@

Write-Host ">> Downloading models..."
$env:HF_HOME = $CacheDir
uv run python -c $downloadScript

$totalBytes = (Get-ChildItem -Recurse $CacheDir -File -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum
if ($totalBytes) {
    Write-Host ("   Cache size: {0:N2} MB" -f ($totalBytes / 1MB))
}
