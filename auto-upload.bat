@echo off
REM 自動上傳腳本 - 每10分鐘執行一次
echo [%date% %time%] 開始自動上傳...

REM 檢查是否有變更
git status --porcelain > temp_status.txt
for /f %%i in (temp_status.txt) do (
    echo 發現檔案變更，正在上傳...
    git add .
    git commit -m "Auto-update: %date% %time%"
    git push origin main
    echo [%date% %time%] 上傳完成
    goto :cleanup
)

echo [%date% %time%] 沒有變更需要上傳

:cleanup
del temp_status.txt
echo 等待10分鐘後再次檢查...
timeout /t 600 /nobreak > nul
goto :start

:start
echo.
echo 重新開始檢查...
goto :eof