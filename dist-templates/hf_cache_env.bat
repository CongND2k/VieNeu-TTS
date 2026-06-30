@echo off
rem Use a short HF cache path to avoid Windows MAX_PATH (WinError 206).
set "HF_HOME=%LOCALAPPDATA%\VieNeu-TTS\hf-cache"
set "HUGGINGFACE_HUB_CACHE=%HF_HOME%"
if not exist "%HF_HOME%" mkdir "%HF_HOME%"
