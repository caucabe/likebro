# MMR - Glassmorphism SwiftUI App

這是一個採用玻璃擬態 (Glassmorphism) 設計風格的 SwiftUI 應用程式，支援 iOS 17 及以上版本，並整合了 Supabase-swift 套件。

## 功能特色

### 🎨 玻璃擬態設計
- **材質背景模糊效果**: 使用 `Material` 背景實現真實的模糊效果
- **圓角設計**: 統一的圓角規範，提供現代化的視覺體驗
- **細微邊框效果**: 半透明邊框增強玻璃質感
- **漸層背景**: 動態漸層背景營造深度感

### 🎯 設計系統
- **Theme.swift**: 統一管理配色方案、字體規範和視覺元素
- **可重用組件**: `GlassmorphismModifier` 和便捷的 View 擴展
- **一致性設計**: 所有頁面遵循相同的設計規範

### 📱 用戶介面
- **儀表板設計**: 清晰的資訊層級和卡片佈局
- **統計卡片**: 展示項目數量和最近活動
- **項目管理**: 新增、刪除和查看項目功能
- **空狀態設計**: 優雅的空狀態提示

### 🔧 技術規格
- **最低支援**: iOS 17.0+
- **框架**: SwiftUI + SwiftData
- **套件整合**: Supabase-swift (Auth, Functions)
- **資料持久化**: SwiftData 本地儲存

## 設計元素

### 顏色系統
- **主色調**: 藍色 (#007AFF)
- **次要色**: 紫色 (#AF52DE)
- **強調色**: 青色 (#32D74B)
- **背景**: 深色漸層 (藍紫到黑色)

### 字體規範
- **大標題**: 34pt, Bold
- **標題**: 22pt, Semibold
- **內文**: 17pt, Regular
- **說明文字**: 15pt, Regular

### 間距系統
- **XS**: 4pt
- **SM**: 8pt
- **MD**: 16pt
- **LG**: 24pt
- **XL**: 32pt

## 使用方式

1. 在 Xcode 中開啟 `mmr.xcodeproj`
2. 選擇 iOS 模擬器或實體裝置
3. 按下 ⌘+R 執行應用程式

## 專案結構

```
mmr/
├── mmr/
│   ├── mmrApp.swift          # 應用程式入口點
│   ├── ContentView.swift     # 主要介面
│   ├── Theme.swift           # 設計系統和主題配置
│   └── Item.swift            # 資料模型
└── mmr.xcodeproj/            # Xcode 專案檔案
```

## 玻璃擬態效果實現

### GlassmorphismModifier
```swift
struct GlassmorphismModifier: ViewModifier {
    // 實現材質背景、模糊效果、圓角和邊框
}
```

### 便捷擴展
```swift
extension View {
    func glassmorphism() -> some View
    func glassCard() -> some View
    func glassButton() -> some View
}
```

這個專案展示了如何在 SwiftUI 中實現現代化的玻璃擬態設計，提供了完整的設計系統和可重用的組件庫。