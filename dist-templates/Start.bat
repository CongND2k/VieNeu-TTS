@echo off
chcp 65001 >nul
cd /d "%~dp0"

call "%~dp0hf_cache_env.bat"
set "HF_HUB_OFFLINE=1"
set "TRANSFORMERS_OFFLINE=1"
set "GRADIO_SERVER_NAME=127.0.0.1"
set "GRADIO_SERVER_PORT=7860"

rem Seed cache from bundled models (CI/pre-built ZIP) on first run.
set "BUNDLED_CACHE=%~dp0runtime\cache\huggingface"
if not exist "%HF_HOME%\hub" if exist "%BUNDLED_CACHE%\hub" (
    echo Dang copy model bundled sang cache ngan: %HF_HOME%
    xcopy /E /I /Y /Q "%BUNDLED_CACHE%\*" "%HF_HOME%\"
)

cd /d "%~dp0app"
set "PYTHONPATH=%~dp0app;%~dp0app\src"

echo Dang khoi dong VieNeu-TTS...
echo Cache model: %HF_HOME%
echo Web UI: http://127.0.0.1:7860
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:7860"

"%~dp0runtime\python\Scripts\python.exe" -m apps.gradio_main

pause
