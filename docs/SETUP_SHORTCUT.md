# Aura 一键壁纸 Shortcut 配置指南

iOS 不允许第三方 app 直接设置壁纸——这是 Apple 的硬限制。Aura 通过 **iOS Shortcuts** 绕开这个限制:

```
[Aura app]  ─调起URL→  [Shortcuts app]  ─调用系统API→  [设置壁纸]
                      "Aura Set Wallpaper"
                      ↑↑↑ 用户一次性建好的快捷指令
```

本指南教你建好 `Aura Set Wallpaper` 这个 Shortcut。整个流程 **~1 分钟**,只做一次。

---

## 方式一: 开发者上线时

如果你是 Aura 的开发者准备上 App Store,请按 **[方式二](#方式二-用户首次使用-或simulator-测试)** 在自己 iPhone 上建一次 Shortcut,然后:

1. 在 Shortcuts.app 里找到 `Aura Set Wallpaper`
2. 长按 → **Share** → **Copy iCloud Link**(得到 `https://www.icloud.com/shortcuts/XXXXXX` 形式的链接)
3. 把它粘到 [`Aura/Services/ShortcutsService.swift`](../Aura/Services/ShortcutsService.swift) 的 `installURL`
4. 重新 build → 用户首次使用时点 "Get the Aura Shortcut" 会直接跳转 iCloud 分享页,他们点一下 "Add Shortcut" 就装好

App 里 `isInstallURLConfigured` 会自动检测占位 URL,所以**未配置时也能跑**(走方式二的 5 步手动建)。

---

## 方式二: 用户首次使用 (或simulator 测试)

### 0. 准备

- 设备: iPhone 真机 或 iOS Simulator(iOS 26+ 才有 Shortcuts.app)
- 时间: ~1 分钟

### 1. 从 Aura 跳过去

在 Aura 里 → Today tab → 点 **Set as Wallpaper** → 弹出 "One-tap wallpaper" sheet → 点 **Open Shortcuts.app**

> Simulator 提示:Mac 菜单栏 **I/O → Keyboard → Connect Hardware Keyboard** 勾上,这样可以用 Mac 键盘直接输入,不用点 simulator 屏幕键盘。

### 2. 新建 Shortcut

进入 Shortcuts.app 后,默认在 **Library** tab。点右上角 **+** 进入新建界面。

你会看到:
- 顶部: ◀ Aura(返回链)、`New Shortcut` 标题、▾ 下拉
- 中间: "Add actions from below to create a shortcut"
- 底部: 搜索栏 + actions 列表

### 3. 加第一个 action: Get Latest Photos

1. 点底部搜索框,输入 `latest photo`
2. 列表里出现 **Get Latest Photos** → 点它
3. action 出现在中间区域,默认参数: `Get Latest 1 Photos`
4. (可选) 点 action 上的 `1` → 改成 `1` 确认,把 "Include Screenshots" 关掉以防截图被误用

### 4. 加第二个 action: Set Wallpaper

1. 滑回底部搜索框,清空,输入 `set wallpaper`
2. 点 **Set Wallpaper**
3. 默认参数: `Set Wallpaper to [Latest Photos]`(Shortcuts 会自动把上一步的输出连过来)
4. (可选)点 ▾ 展开 → 关 "Show Preview"(默认关着的话就跳过)、设 "Lock Screen" 和 "Home Screen" 都开

### 5. 重命名

1. 点顶部的 **New Shortcut** 文字(或它旁边的 ▾)
2. 弹出菜单 → 点 **Rename**
3. 输入精确的:

   ```
   Aura Set Wallpaper
   ```

   ⚠️ **大小写敏感、空格敏感**,Aura app 通过这个名字调起,差一个字符就找不到。
4. 按 Done

### 6. 退出 (自动保存)

左上角点 **◀ Library** 或者直接关 Shortcuts.app。Shortcut 已经保存到你的 Library 里。

### 7. 回 Aura 验证

1. 切回 Aura(顶部 `◀ Aura` 或 App Switcher)
2. 之前的安装 sheet 还在 → 点 **I've installed it**
3. iOS 弹出 "Allow 'Aura Set Wallpaper' to access photos?" → **Allow**
4. iOS 再弹 "Set as wallpaper?" → 选 **Set Both Lock Screen and Home Screen**
5. 完成 ✨ 退到桌面看一眼

---

## 验证 Shortcut 工作正常

不通过 Aura 也能直接测:

- **方式 A**: Shortcuts.app → 找到 `Aura Set Wallpaper` → 点它 → 看是否能跑通
- **方式 B**: Safari 输入 `shortcuts://run-shortcut?name=Aura%20Set%20Wallpaper` → 看是否调起

---

## 常见问题

### Q: 点 "I've installed it" 之后没反应?

可能原因:
1. Shortcut 名字不是精确的 `Aura Set Wallpaper`(注意大小写、空格)
2. Shortcuts.app 没装(只在 iOS 26+ simulator 才有,旧版 simulator 不带)
3. `LSApplicationQueriesSchemes` 没声明 `shortcuts`(已经在 `project.yml` 里加好)

### Q: Shortcut 跑起来但壁纸没换?

- 检查 "Get Latest Photos" 的 Count = 1
- 检查 "Set Wallpaper" 的输入是否正确连到上一个 action 的输出
- iOS 17.4+ 起,系统每次都会弹"确认设置"的对话框,这是 Apple 加的硬限制,不能跳过

### Q: 用户每次都要 Allow 一次?

第一次会要求授权 Photos 访问,之后就不弹了。但 iOS 17.4+ 的 "Set as wallpaper?" 确认弹窗每次都会有,这是系统行为不可改。

### Q: 我能给用户预装这个 Shortcut 吗?

不能直接预装,但你可以**用 iCloud 链接一键安装**——按 [方式一](#方式一-开发者上线时) 配置 `installURL`,用户点 "Get the Aura Shortcut" 跳到 iCloud,点 "Add Shortcut" 就装好(比手动建省 4 步)。

---

## 上线 checklist

部署前确认:

- [ ] 自己 iPhone 上建好 `Aura Set Wallpaper` Shortcut
- [ ] 拿到 iCloud share link
- [ ] [`ShortcutsService.swift`](../Aura/Services/ShortcutsService.swift) 的 `installURL` 已换成真链接
- [ ] App 显示 "Get the Aura Shortcut"(而不是 "Open Shortcuts.app",后者是占位模式)
- [ ] 在另一台 iPhone(或抹掉重装)上跑完整流程: 生成壁纸 → Set as Wallpaper → 跳 iCloud → Add Shortcut → 回 Aura → I've installed it → 系统确认 → 壁纸换好
