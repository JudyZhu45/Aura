# Aura Lock Screen Widget — 添加 + 验证指南

iOS 16+ 支持把第三方 widget 放到锁屏。Aura 提供 3 种 family,装好后每天生成新壁纸时会自动刷新。

---

## 架构(代码层已完成)

```
主 App ←──[App Group: group.com.aura.app]──→ Widget Extension
    │                                              │
    │   WallpaperStore.publishToWidget()          │
    │   写入:                                       │
    │     • shared UserDefaults                    │
    │     • today.jpg (~256px JPEG, <120 KB)       │
    │   触发: WidgetCenter.reloadAllTimelines()    │
    │                                              │
    ▼                                              ▼
SharedStorage.readTodaySnapshot()         AuraTimelineProvider
                                          (每天 00:01 刷新)
                                                   │
                                                   ▼
                                          AuraWidgetEntryView
                                          ┌──────┬──────┬────────────┐
                                          │ 🔵   │ 🔵 Aura │ ✨ Today │
                                          │      │ Calm    │   Calm   │
                                          └──────┴──────┴────────────┘
                                          circular  rectangular  inline
```

## 3 种 widget family

| Family | 位置 | 显示内容 |
|---|---|---|
| **accessoryCircular** | 时钟下面圆形槽位 / Always-on Display | 今日壁纸缩略图(锁屏会被 iOS 自动 tint 成单色) |
| **accessoryRectangular** | 时钟下方长条 | 小缩略图 + "Today's Aura" 标签 + Mood |
| **accessoryInline** | 时钟正上方单行 | `✨ Today: Calm` 或引导文案 |

> ⚠️ **锁屏 widget 的渲染限制**: iOS 用 `.accented` 模式渲染所有锁屏 widget,**强制把图像 tint 成单色**。所以即使我们传了彩色 JPEG,锁屏上看到的会是单色剪影。这是 Apple 的硬限制(为了和 lock screen 美学一致)。如果你要全彩缩略图,得用 **Home Screen widget**(`systemSmall`,后续可加)。

---

## 在真机上加 widget(最简单)

1. 长按锁屏空白处 → **Customize**
2. 选 **Lock Screen** 那一边
3. 点 **+ Add Widgets** 或时钟下方/上方的 widget 槽
4. 列表里找 **Aura**(应该在最近装的 app 里)
5. 拖一个 `accessoryRectangular` 到时钟下方,或 `accessoryCircular` 到圆形槽
6. 点 **Done** → 退出 customize 模式
7. 锁屏看,应该立刻显示今日 Aura 的内容

如果显示 "Tap to generate" — 说明你还没生成今日壁纸,打开 Aura 生成一次,锁屏 widget 几秒后自动刷新。

---

## 在 Simulator 上加 widget(较绕)

Simulator 的"长按锁屏"手势不太灵(模拟器没设密码,点一下就解锁,长按经常被识别成单击)。两种解决:

### 方式 A: 通过 Settings
1. Settings.app → Wallpaper → Customize Current(或 + Add New Wallpaper)
2. 选 Lock Screen → 点时钟下方的 widget 槽
3. 找 Aura → 添加 → Done

### 方式 B: 用 Xcode 启动调试 widget(开发期最方便)

```bash
open /Users/judy459/Aura/Aura.xcodeproj
```

在 Xcode:
1. Scheme 切换到 `AuraWidgets`(原本是 Aura)
2. 按 ⌘R
3. Xcode 弹一个对话框 "Choose an app to run" → 选 Today / Home Screen / Lock Screen 任意一个 widget family
4. Xcode 在 simulator 上直接以全屏单 widget 渲染该 family,可以快速看效果、断点调试

> 这是 iOS WidgetKit 开发者专属调试通道,不是用户路径。

---

## 验证 widget 在工作

### 1. 共享存储有数据吗?

```bash
SIM_UUID=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
find ~/Library/Developer/CoreSimulator/Devices/$SIM_UUID/data/Containers/Shared/AppGroup -name "today.jpg"
```

如果输出一个路径 + 文件存在,说明 `WallpaperStore.publishToWidget()` 跑过、shared container 写好了。

### 2. UserDefaults metadata 写好了吗?

```bash
GROUP_DIR=$(find ~/Library/Developer/CoreSimulator/Devices/$SIM_UUID/data/Containers/Shared/AppGroup -name "today.jpg" | head -1)
plutil -p $(dirname $GROUP_DIR)/Library/Preferences/group.com.aura.app.plist
```

应该看到 `today.mood`、`today.palette`、`today.artStyle`、`today.date`、`today.hasContent` 5 个 key。

### 3. 触发 widget reload

强制让 widget 刷新一下:

```bash
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.apple.widgetkit"' --level debug
```

打开主 app 生成一张新壁纸,这条 log stream 应该看到 widget timeline 被 reload。

---

## Tap widget 跳回主 app

每个 widget 都用了 `.widgetURL(URL(string: "aura://today"))`。iOS 收到后:

1. 启动主 app
2. 调用 `ContentView.onOpenURL`
3. 根据 host 切 tab:
   - `aura://today` → Today tab
   - `aura://generate` → Generate tab
   - `aura://history` → History tab

URL scheme 在 `project.yml` 的 `CFBundleURLTypes` 里声明了 `aura`,所以 iOS 知道该把 `aura://` 路由给我们。

---

## 上线 checklist

- [ ] App Group `group.com.aura.app` 在 Apple Developer Portal 创建(开发期 simulator 不需要,真机和上线需要)
- [ ] 主 app 和 widget extension 的 Bundle ID 都启用了这个 App Group
- [ ] 在 Apple Developer Portal 注册了 `com.aura.app.widgets` 这个 widget extension bundle ID
- [ ] Provisioning Profiles 都更新了 App Group capability
- [ ] 真机上跑一次完整流程: 生成壁纸 → 锁屏加 widget → 验证显示对
- [ ] 准备 widget 在 App Store Connect 的市场截图(每个 family 一张)
