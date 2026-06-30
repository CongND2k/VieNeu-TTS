@echo off
chcp 65001 >nul
cd /d "%~dp0"

set "HF_HOME=%~dp0runtime\cache\huggingface"
set "HF_HUB_OFFLINE="
set "TRANSFORMERS_OFFLINE="

rem Neu loi tai model (dac biet OpenMOSS-Team), bo comment dong duoi:
rem set "HF_ENDPOINT=https://hf-mirror.com"

if not exist "%~dp0runtime\python\Scripts\python.exe" (
    echo Khong tim thay Python portable. Hay chay Start.bat sau khi giai nen dung folder.
    pause
    exit /b 1
)

if not exist "%~dp0download_portable_models.py" (
    echo Thieu download_portable_models.py. Hay tai lai ban portable moi hon.
    pause
    exit /b 1
)

echo Dang tai model HuggingFace ve: %HF_HOME%
echo Can ket noi internet. Qua trinh nay co the mat vai phut...
echo.

"%~dp0runtime\python\Scripts\python.exe" "%~dp0download_portable_models.py"
set "DL_EXIT=%ERRORLEVEL%"

if not "%DL_EXIT%"=="0" (
    echo.
    echo Tai model chua xong. Xem loi o tren va thu lai.
    pause
    exit /b %DL_EXIT%
)

echo.
echo Hoan tat. Bay gio co the chay Start.bat offline.
pause
