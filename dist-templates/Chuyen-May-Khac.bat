@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo  VieNeu-TTS Portable - Chuyen sang may khac
echo ========================================
echo.
echo Copy TOAN BO folder nay (VieNeu-TTS-Portable) sang:
echo   - USB / o cung may dich (nen dat duong dan ngan, vi du C:\VieNeu-TTS)
echo   - May dich: Windows 10/11 x64, khong can cai Python
echo.
echo Thu tu tren may dich:
echo   1. Giai nen / dan folder (neu copy tu ZIP)
echo   2. Neu chua co model: chay Download-Models.bat (can internet)
echo   3. Chay Start.bat - mo http://127.0.0.1:7860
echo.
echo File quan trong trong folder nay:
echo   Start.bat                  - khoi dong ung dung
echo   Download-Models.bat        - tai model (lan dau / khi thieu)
echo   hf_cache_env.bat             - cau hinh cache (goi tu cac file tren)
echo   download_portable_models.py  - script tai model
echo   runtime\python\              - Python portable
echo   runtime\cache\huggingface\   - model bundled (neu build day du)
echo   app\                          - ung dung Gradio
echo.
echo Cache khi chay (may dich): %%LOCALAPPDATA%%\VieNeu-TTS\hf-cache
echo.
pause
