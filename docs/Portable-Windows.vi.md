# Đóng gói VieNeu-TTS portable cho Windows (build từ Mac)

Hướng dẫn tạo bản **copy folder là chạy** trên Windows, trong khi bạn phát triển trên macOS.

## Tổng quan

VieNeu-TTS dùng Python + Gradio. Runtime Windows **phải build trên Windows** (wheel `onnxruntime`, `sea-g2p`… không cross-compile được từ Mac).

Giải pháp: script trên Mac điều phối build qua **GitHub Actions** hoặc **đóng gói source** sang máy Windows.

| File | Chạy trên | Mục đích |
|------|-----------|----------|
| `scripts/build-windows.sh` | Mac/Linux | Entry point chính |
| `scripts/build-portable.ps1` | Windows | Build folder portable + ZIP |
| `scripts/download-models.ps1` | Windows | Tải model HuggingFace offline |
| `scripts/validate-portable.ps1` | Windows | Kiểm tra cấu trúc folder sau build |
| `dist-templates/Start.bat` | — | Launcher cho người dùng cuối |
| `.github/workflows/build-portable-windows.yml` | CI | Build tự động trên Windows |

## Cách A — GitHub Actions (khuyến nghị)

### Yêu cầu trên Mac

```bash
brew install gh
gh auth login
```

Repo phải push lên GitHub và bật Actions.

### Build và tải ZIP

```bash
cd ~/Code/VieNeu-TTS
chmod +x scripts/build-windows.sh
./scripts/build-windows.sh --wait
```

Kết quả: `dist/VieNeu-TTS-Portable-win64.zip`

Chỉ trigger CI (không chờ):

```bash
./scripts/build-windows.sh
```

Theo dõi thủ công:

```bash
gh run list --workflow=build-portable-windows.yml
gh run watch <run-id>
gh run download <run-id> -D dist/
```

### Trên máy Windows đích

1. Giải nén ZIP
2. Double-click `Start.bat`
3. Trình duyệt mở `http://127.0.0.1:7860`
4. Không cần cài Python hay internet (offline)

## Cách B — Máy Windows / Parallels (không dùng CI)

Trên Mac:

```bash
./scripts/build-windows.sh --local
```

Tạo `dist/vieneu-source-for-windows.zip`. Copy sang Windows, giải nén, rồi:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-portable.ps1
```

Output: `dist\VieNeu-TTS-Portable-win64.zip`

## Cấu trúc bản portable

```
VieNeu-TTS-Portable/
├── Start.bat
├── README.txt
├── runtime/
│   ├── python/              # .venv (Python + thư viện)
│   └── cache/huggingface/   # model ONNX đã tải sẵn
└── app/
    ├── apps/
    ├── src/
    └── config.yaml
```

## Biến thể build

- **CPU + v3 Turbo ONNX** (mặc định): `uv sync` không GPU
- Không cần eSpeak (`sea-g2p` thay thế)
- Model offline:
  - `pnnbao-ump/VieNeu-TTS-v3-Turbo`
  - `OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX`
- Dung lượng ước tính: **2–5 GB**

## Kiểm thử trên Windows sạch

Trước khi phát hành, test trên máy/VM **chưa cài Python**:

- [ ] Double-click `Start.bat` → Web UI mở tại `:7860`
- [ ] TTS giọng mặc định hoạt động **không cần mạng**
- [ ] Voice cloning với file mẫu trong `app/src/vieneu/assets/samples/`
- [ ] Copy folder sang ổ khác/USB vẫn chạy

## Xử lý sự cố

| Vấn đề | Cách xử lý |
|--------|------------|
| Port 7860 bị chiếm | Sửa `GRADIO_SERVER_PORT` trong `Start.bat` |
| Antivirus chặn Python | Whitelist folder portable |
| CI timeout | Workflow đặt `timeout-minutes: 90`; model cache qua `actions/cache` |
| Model private | Thêm secret `HF_TOKEN` vào repo GitHub |
| Lỗi `huggingface_hub` / `get_hf_file_metadata` | Model chưa có trong cache offline. Double-click `Download-Models.bat` (cần internet), hoặc tải lại ZIP portable đầy đủ từ GitHub Releases. Kiểm tra folder `runtime\cache\huggingface\hub` có dữ liệu (~2–5 GB). |
| Lỗi tải `OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX` | Thường do mạng/VPN tới Hugging Face (file VieNeu đã tải xong nhưng MOSS bị ngắt). Mở `Download-Models.bat`, bỏ comment `set HF_ENDPOINT=https://hf-mirror.com`, chạy lại — script sẽ resume file đã tải. |
| Không vào được huggingface.co | Bật VPN/proxy, hoặc đặt mirror: `set HF_ENDPOINT=https://hf-mirror.com` trong `Download-Models.bat` trước khi tải |

## Tag release portable

Push tag để tự động build:

```bash
git tag portable-v1.0.0
git push origin portable-v1.0.0
```

Workflow `.github/workflows/build-portable-windows.yml` sẽ chạy trên `windows-latest`.
