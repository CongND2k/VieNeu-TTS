@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "HF_HOME=%~dp0runtime\cache\huggingface"
set "HF_HUB_OFFLINE=1"
set "TRANSFORMERS_OFFLINE=1"
set "GRADIO_SERVER_NAME=127.0.0.1"
set "GRADIO_SERVER_PORT=7860"

cd /d "%~dp0app"
set "PYTHONPATH=%~dp0app;%~dp0app\src"

echo Dang khoi dong VieNeu-TTS...
echo Web UI: http://127.0.0.1:7860
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:7860"

"%~dp0runtime\python\Scripts\python.exe" -m apps.gradio_main

pause
