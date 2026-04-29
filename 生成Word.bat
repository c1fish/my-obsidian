@echo off
chcp 65001 >nul
python "%~dp0231301-3123002261-余卓成.py"
if errorlevel 1 (
    echo.
    echo 执行失败，请确保已安装 Python 并在 PATH 中。
    echo 下载地址: https://www.python.org/downloads/
)
pause
