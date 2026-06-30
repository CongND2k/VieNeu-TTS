@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "HF_HOME=%~dp0runtime\cache\huggingface"
set "HF_HUB_OFFLINE="
set "TRANSFORMERS_OFFLINE="

if not exist "%~dp0runtime\python\Scripts\python.exe" (
    echo Khong tim thay Python portable. Hay chay Start.bat sau khi giai nen dung folder.
    pause
    exit /b 1
)

echo Dang tai model HuggingFace ve: %HF_HOME%
echo Can ket noi internet. Qua trinh nay co the mat vai phut...
echo.

"%~dp0runtime\python\Scripts\python.exe" -c "import os; os.makedirs(os.environ['HF_HOME'], exist_ok=True); from huggingface_hub import hf_hub_download; downloads=[('pnnbao-ump/VieNeu-TTS-v3-Turbo','onnx/vieneu_prefill.onnx'),('pnnbao-ump/VieNeu-TTS-v3-Turbo','onnx/vieneu_decode_step.onnx'),('pnnbao-ump/VieNeu-TTS-v3-Turbo','onnx/vieneu_acoustic_cached.onnx'),('pnnbao-ump/VieNeu-TTS-v3-Turbo','onnx/vieneu_backbone_shared.data'),('pnnbao-ump/VieNeu-TTS-v3-Turbo','onnx/vieneu_v3_heads.npz'),('pnnbao-ump/VieNeu-TTS-v3-Turbo','config.json'),('pnnbao-ump/VieNeu-TTS-v3-Turbo','tokenizer.json'),('OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX','moss_audio_tokenizer_decode_full.onnx'),('OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX','moss_audio_tokenizer_decode_shared.data'),('OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX','moss_audio_tokenizer_encode.onnx'),('OpenMOSS-Team/MOSS-Audio-Tokenizer-Nano-ONNX','moss_audio_tokenizer_encode.data')]; [print(f'   {r} :: {f}') or hf_hub_download(repo_id=r, filename=f, repo_type='model') for r,f in downloads]; print('>> Tai model xong. Hay chay Start.bat.')"

if errorlevel 1 (
    echo.
    echo Tai model that bai. Kiem tra internet/VPN/proxy toi huggingface.co
    pause
    exit /b 1
)

echo.
echo Hoan tat. Bay gio co the chay Start.bat offline.
pause
