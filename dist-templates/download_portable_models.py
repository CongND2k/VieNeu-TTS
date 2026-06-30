"""Download Hugging Face artifacts for the VieNeu-TTS portable build."""
from __future__ import annotations

import os
import sys
import time
from typing import Iterable, Tuple

DOWNLOADS: Tuple[Tuple[str, str], ...] = (
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
)

MAX_ATTEMPTS = 4
RETRY_DELAY_SEC = 5


def _print_env() -> None:
    hf_home = os.environ.get("HF_HOME") or os.environ.get("HUGGINGFACE_HUB_CACHE") or "(default)"
    endpoint = os.environ.get("HF_ENDPOINT") or "https://huggingface.co"
    print(f"HF_HOME={hf_home}")
    print(f"HF_ENDPOINT={endpoint}")
    print()


def _download_one(repo_id: str, filename: str) -> None:
    from huggingface_hub import hf_hub_download

    last_exc: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            path = hf_hub_download(
                repo_id=repo_id,
                filename=filename,
                repo_type="model",
                resume_download=True,
            )
            print(f"   OK -> {path}")
            return
        except Exception as exc:
            last_exc = exc
            print(f"   FAIL attempt {attempt}/{MAX_ATTEMPTS}: {type(exc).__name__}: {exc}")
            if attempt < MAX_ATTEMPTS:
                time.sleep(RETRY_DELAY_SEC)
    assert last_exc is not None
    raise last_exc


def download_all(items: Iterable[Tuple[str, str]] = DOWNLOADS) -> int:
    hf_home = os.environ.get("HF_HOME")
    if hf_home:
        os.makedirs(hf_home, exist_ok=True)
    _print_env()

    failed: list[tuple[str, str, str]] = []
    for repo_id, filename in items:
        label = f"{repo_id} :: {filename}"
        print(label)
        try:
            _download_one(repo_id, filename)
        except Exception as exc:
            failed.append((repo_id, filename, f"{type(exc).__name__}: {exc}"))

    print()
    if failed:
        print("Tai model that bai / Download failed for:")
        for repo_id, filename, err in failed:
            print(f"  - {repo_id} :: {filename}")
            print(f"    {err}")
        print()
        print("Go y / Tips:")
        print("  1. Kiem tra internet, thu lai Download-Models.bat (file da tai se duoc resume).")
        print("  2. Neu khong vao duoc huggingface.co, dat mirror truoc khi chay:")
        print("       set HF_ENDPOINT=https://hf-mirror.com")
        print("  3. Neu dung proxy cong ty, dat HTTPS_PROXY/HTTP_PROXY.")
        print("  4. Tat tam antivirus neu no chan file .onnx/.data dang tai.")
        return 1

    print(">> Tai model xong. Hay chay Start.bat.")
    return 0


if __name__ == "__main__":
    sys.exit(download_all())
