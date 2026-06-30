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
# Leave headroom for hub\models--...\snapshots\...\onnx\... on Windows (MAX_PATH ~260).
MAX_HF_HOME_LEN = 80


def _default_short_hf_home() -> str:
    local_app = os.environ.get("LOCALAPPDATA")
    if local_app:
        return os.path.join(local_app, "VieNeu-TTS", "hf-cache")
    return os.path.join(os.path.expanduser("~"), ".vieneu-tts", "hf-cache")


def ensure_short_hf_home() -> str:
    """Pick a cache dir that stays under the Windows path-length limit."""
    hf_home = os.environ.get("HF_HOME") or os.environ.get("HUGGINGFACE_HUB_CACHE")
    if sys.platform == "win32":
        short_home = _default_short_hf_home()
        if not hf_home or len(os.path.abspath(hf_home)) > MAX_HF_HOME_LEN:
            if hf_home and os.path.abspath(hf_home) != os.path.abspath(short_home):
                print(
                    "Duong dan cache qua dai tren Windows; chuyen sang cache ngan:\n"
                    f"  {hf_home}\n"
                    f"  -> {short_home}"
                )
            hf_home = short_home
        os.environ["HF_HOME"] = hf_home
        os.environ["HUGGINGFACE_HUB_CACHE"] = hf_home
    elif hf_home:
        os.environ.setdefault("HF_HOME", hf_home)
        os.environ.setdefault("HUGGINGFACE_HUB_CACHE", hf_home)
    else:
        hf_home = _default_short_hf_home()
        os.environ["HF_HOME"] = hf_home
        os.environ["HUGGINGFACE_HUB_CACHE"] = hf_home
    return hf_home


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
    hf_home = ensure_short_hf_home()
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
        print("  3. Neu thay WinError 206 / filename too long: cache da chuyen ve")
        print("       %LOCALAPPDATA%\\VieNeu-TTS\\hf-cache (duong dan ngan).")
        print("  4. Neu dung proxy cong ty, dat HTTPS_PROXY/HTTP_PROXY.")
        print("  5. Tat tam antivirus neu no chan file .onnx/.data dang tai.")
        return 1

    print(">> Tai model xong. Hay chay Start.bat.")
    return 0


if __name__ == "__main__":
    sys.exit(download_all())
