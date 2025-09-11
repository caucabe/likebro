# 玻璃拟态风格登入/注册系统

一個採用現代玻璃拟态（Glassmorphism）設計風格的登入/註冊系統，具備完整的用戶認證流程和無障礙支援。

## 專案特色

- 🎨 **玻璃拟态設計**：現代化的半透明玻璃效果
- 📱 **響應式設計**：完美適配各種螢幕尺寸
- 🔐 **完整認證流程**：登入/註冊/OTP驗證
- 🚀 **第三方登入**：支援 Google、Facebook、Apple
- ♿ **無障礙支援**：符合 WCAG 標準
- 🎭 **動態效果**：流暢的動畫和互動反饋

## 檔案結構

```
├── index.html          # 主頁面（歡迎頁面）
├── auth.html           # 認證頁面（登入/註冊）
├── styles.css          # 主頁面樣式
├── auth.css            # 認證頁面樣式
├── app.js              # 主頁面邏輯
├── auth.js             # 認證頁面邏輯
├── deploy-to-github.bat # GitHub 部署腳本
├── auto-upload.bat     # 自動上傳腳本
└── README.md           # 專案說明
```

## 快速開始

1. **本地預覽**
   ```bash
   # 直接開啟 index.html 或使用本地伺服器
   start index.html
   ```

2. **部署到 GitHub**
   ```bash
   # 執行部署腳本
   deploy-to-github.bat
   ```

3. **啟用自動上傳**
   ```bash
   # 每10分鐘自動檢查並上傳變更
   auto-upload.bat
   ```

## 部署步驟

### 手動部署

1. 在 GitHub 上創建新儲存庫 `glassmorphism-auth-system`
2. 編輯 `deploy-to-github.bat`，取消註解並替換儲存庫 URL
3. 執行部署腳本

### 自動部署

1. 完成手動部署後
2. 執行 `auto-upload.bat` 啟用定期上傳
3. 系統將每10分鐘自動檢查變更並上傳

## 技術規格

- **前端框架**：原生 HTML5/CSS3/JavaScript
- **設計風格**：Glassmorphism（玻璃拟态）
- **響應式**：CSS Grid + Flexbox
- **動畫**：CSS Transitions + Transforms
- **無障礙**：ARIA 標籤 + 鍵盤導航

## 功能說明

### 主頁面 (index.html)
- 歡迎介面設計
- 玻璃拟态背景效果
- 動態漸變動畫
- CTA 按鈕導向認證頁面

### 認證頁面 (auth.html)
- 登入/註冊標籤切換
- 第三方快捷登入（Google、Facebook、Apple）
- 手機號碼輸入與格式化
- OTP 驗證對話框
- Toast 通知系統
- 完整的鍵盤導航支援

## 瀏覽器支援

- Chrome 88+
- Firefox 87+
- Safari 14+
- Edge 88+

## 授權

MIT License - 可自由使用於個人或商業專案

---

**開發時間**：2025年1月
**最後更新**：自動上傳系統啟用