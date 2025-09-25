# 自動上傳腳本 - PowerShell 版本
# 每10分鐘檢查並上傳變更到 GitHub

Write-Host "=== 玻璃拟态認證系統 - 自動上傳腳本 ===" -ForegroundColor Cyan
Write-Host "每10分鐘自動檢查並上傳變更" -ForegroundColor Yellow
Write-Host ""

# 設定工作目錄
Set-Location $PSScriptRoot

# 檢查是否為 Git 儲存庫
if (-not (Test-Path ".git")) {
    Write-Host "初始化 Git 儲存庫..." -ForegroundColor Green
    git init
    Write-Host "請手動設定遠端儲存庫：" -ForegroundColor Yellow
    Write-Host "git remote add origin https://github.com/lucky/glassmorphism-auth-system.git" -ForegroundColor White
    Write-Host ""
}

# 主循環
while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] 檢查檔案變更..." -ForegroundColor Gray
    
    # 檢查 Git 狀態
    $gitStatus = git status --porcelain
    
    if ($gitStatus) {
        Write-Host "發現變更，正在上傳..." -ForegroundColor Green
        
        # 顯示變更的檔案
        Write-Host "變更的檔案：" -ForegroundColor Yellow
        $gitStatus | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        
        # 添加所有變更
        git add .
        
        # 提交變更
        $commitMessage = "Auto-update: $timestamp"
        git commit -m $commitMessage
        
        # 推送到遠端
        try {
            git push origin main
            Write-Host "[$timestamp] 上傳成功！" -ForegroundColor Green
        }
        catch {
            Write-Host "[$timestamp] 上傳失敗：$_" -ForegroundColor Red
            Write-Host "請檢查網路連線和 Git 設定" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[$timestamp] 沒有變更需要上傳" -ForegroundColor Gray
    }
    
    Write-Host "等待10分鐘後再次檢查..." -ForegroundColor Cyan
    Write-Host "按 Ctrl+C 停止自動上傳" -ForegroundColor Yellow
    Write-Host ""
    
    # 等待10分鐘（600秒）
    Start-Sleep -Seconds 600
}