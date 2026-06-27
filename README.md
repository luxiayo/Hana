# 🌸 Hana

Hana 是一个使用 SwiftUI 构建的 Hanime1 客户端，面向 iOS / iPadOS，兼容 iOS 16+。

## 主要功能

- 首页发现、横幅推荐
- 视频搜索、筛选、观看记录、收藏、稍后观看、播放清单
- 视频详情页、评论、相关推荐、清晰度选择
- AVKit 播放器、画中画、循环播放、长按倍速、播放进度恢复
- HKeyframes 关键帧、共享记录、倒计时提示和剪贴板导入
- 下载队列、分组管理和本地播放

## 技术栈

- SwiftUI
- JSONPersistence（Codable + 文件持久化，替代 SwiftData）
- AVKit / AVFoundation
- URLSession
- Nuke
- SwiftSoup

## 项目说明

本项目从仅支持 iOS 26+ 的原始版本重构而来，核心改动：

- **SwiftData** → **JSONPersistence**：使用 `Codable` + JSON 文件实现数据持久化，移除 `@Model` / `@Query` 依赖
- **`@Observable` macro** → **`ObservableObject` + `@Published`**：兼容 iOS 16 的响应式编程模型
- **iOS 18+ Tab API** → **传统 `TabView` + `.tabItem`**：使用平台兼容的导航方式
- **移除 iOS 17+ 专有 API**：如 `ContentUnavailableView`、`sensoryFeedback`、`.symbolEffect`、`.visualEffect`、`.onScrollGeometryChange` 等

## 运行项目

1. 使用 Xcode 打开 `Hana.xcodeproj`
2. 选择 `Hana` scheme
3. 选择运行目标，例如 iPhone Simulator
4. 直接 Build / Run

也可以使用命令行构建：

```bash
xcodebuild -project Hana.xcodeproj -scheme Hana -destination 'generic/platform=iOS Simulator' build
```

## 开发注意事项

- `build/`、`DerivedData/`、`xcuserdata/`、`.DS_Store` 等本地产物不应提交
- `Package.resolved` 应保留提交，方便复现依赖版本
- 项目最低支持 iOS 16.0，请注意不要引入新版本专有 API

## 已知问题 / 待修复事项

### 下载模块

#### 1. 下载状态无法实时更新
点击下载按钮后，UI 中条目状态一直显示为「等待下载」，不会更新为「下载中」。

**可能原因**：`HanimeDownloadClient` 的进度更新（`updateProgress`）写入 `HanimeDownloadTaskStateStore`（tasks.json）后，通过 `syncTaskToPersistence()` 同步到 `JSONPersistenceManager`（downloadQueue.json），但 `DownloadsScreen` 的 Combine 订阅或 SwiftUI 渲染链路未正确触发差异化更新。`@Published` 字典的 in-place mutation（`dict[key] = value`）不触发 `objectWillChange`，已添加显式 `.send()` 但 UI 仍未响应。

#### 2. 下载完成后状态仍不更新
后台下载成功（本地文件系统中已存在视频文件），重新进入页面或下拉刷新后，UI 中的状态仍然显示为「等待下载」。

**可能原因**：下载完成回调 `completeTask` 中 `stateStore.markCompleted` 和 `syncTaskToPersistence` 已执行（tasks.json 和 downloadQueue.json 均已正确写入），但 `DownloadsScreen` 未能从 `JSONPersistenceManager` 重新加载最新数据。

#### 3. 删除记录后残留缓存
左滑删除条目后，文件系统已被清理，但重新进入「已下载的视频」页面，该条目仍然显示在列表中，状态变为「已取消」。

**可能原因**：`cancel()` 方法调用了 `objectWillChange.send()`，触发了 `onReceive` 中的 `loadDownloadRecords()`。当删除函数执行 `persistence.deleteDownloadQueue(item)` 时，`onReceive` 的并发竞态导致已删除的记录在 UI 中短暂恢复。

#### 4. 重新下载后状态仍错误
在删除后点击「重新下载」按钮，虽然文件确实被重新下载（本地能查看文件），但 UI 中状态依然显示为「已取消」。

**可能原因**：`download()` 启动新任务时调用了 `syncTaskToPersistence(requestID:)`，但由于之前 `cancel()` 已将 `stateStore`（tasks.json）中该任务的 ID 标记为「cancelled」，`download()` 调用 `stateStore.markRunning()` 时可能复用了旧的 cancelled 状态记录，导致同步后的 `downloadQueue.json` 状态异常。

## 许可证

Hana 采用 GNU Affero General Public License v3.0 or later 发布。完整许可证见 [LICENSE](LICENSE)。

Copyright 2026-present Kanscape and contributors.

本项目是使用 SwiftUI 实现的 Hanime1 客户端。部分搜索选项资源和 HKeyframes 资源来自 Han1meViewer，并按 Apache License 2.0 保留原始版权声明和许可证文本。第三方依赖与资源来源见 [NOTICE](NOTICE) 和 [LICENSES](LICENSES)。

## 免责声明

本项目仅作为客户端实现使用。使用时应遵守目标站点的服务条款、当地法律法规和内容访问限制。
