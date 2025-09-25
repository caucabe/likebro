@echo off
echo 正在準備上傳到 GitHub...
echo.

REM 初始化 Git 儲存庫
git init

REM 添加所有檔案
git add .

REM 創建初始提交
git commit -m "Initial commit: Glassmorphism Auth System"

REM 添加遠端儲存庫 (請替換為您的實際儲存庫 URL)
REM git remote add origin https://github.com/lucky/glassmorphism-auth-system.git

REM 推送到 GitHub
REM git branch -M main
REM git push -u origin main

echo.
echo 請手動執行以下步驟：
echo 1. 在 GitHub 上創建新儲存庫 'glassmorphism-auth-system'
echo 2. 取消註解上方的 git remote add 和 git push 命令
echo 3. 替換為您的實際儲存庫 URL
echo 4. 重新執行此腳本
echo.
pause