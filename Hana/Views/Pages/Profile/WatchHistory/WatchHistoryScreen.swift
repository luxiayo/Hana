import AVKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct WatchHistoryScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WatchHistoryRecord.watchDate, order: .reverse) private var watchHistory: [WatchHistoryRecord]
    @State private var isClearConfirmationPresented = false
    @State private var isSelectionModeActive = false
    @State private var selectedVideoCodes = Set<String>()
    @State private var isSelectedDeleteConfirmationPresented = false

    var body: some View {
        content
            .navigationTitle("观看记录")
            .toolbar {
                if shouldShowToolbarActions {
                    watchHistoryToolbar
                }
            }
            .confirmationDialog("清空全部观看记录？", isPresented: $isClearConfirmationPresented, titleVisibility: .visible) {
                Button("清空", role: .destructive) {
                    clearAll()
                }
                Button("取消", role: .cancel) {}
            }
            .confirmationDialog("删除所选观看记录？", isPresented: $isSelectedDeleteConfirmationPresented, titleVisibility: .visible) {
                Button("删除 \(selectedVideoCodes.count) 条记录", role: .destructive) {
                    deleteSelected()
                }
                Button("取消", role: .cancel) {}
            }
    }

    @ViewBuilder
    private var content: some View {
        if visibleWatchHistory.isEmpty {
            ContentUnavailableView("暂无观看记录", systemImage: "clock.arrow.circlepath")
        } else {
            watchHistoryList
        }
    }

    private var watchHistoryList: some View {
        List {
            watchHistoryRows
        }
    }

    @ToolbarContentBuilder
    private var watchHistoryToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if isEditing {
                HanaToolbarIconButton(title: "退出选择", systemImage: "xmark", action: toggleEditMode)

                HanaToolbarIconButton(
                    title: areAllVisibleItemsSelected ? "取消全选" : "全选",
                    systemImage: areAllVisibleItemsSelected ? "circle" : "checkmark.circle"
                ) {
                    toggleAll()
                }
                .disabled(visibleWatchHistory.isEmpty)

                HanaToolbarIconButton(title: "删除所选 \(selectedVideoCodes.count)", systemImage: "trash", role: .destructive) {
                    isSelectedDeleteConfirmationPresented = true
                }
                .disabled(selectedVideoCodes.isEmpty)
            } else {
                Button(action: toggleEditMode) {
                    Label("选择", systemImage: "checklist")
                }
                .disabled(visibleWatchHistory.isEmpty)

                Button(role: .destructive) {
                    isClearConfirmationPresented = true
                } label: {
                    Label("清空观看记录", systemImage: "trash")
                }
            }
        }
    }

    private var watchHistoryRows: some View {
        Group {
            if isEditing {
                ForEach(visibleWatchHistory) { item in
                    HanaSelectableRow(
                        isSelected: selectedVideoCodes.contains(item.videoCode),
                        accessibilityLabel: item.title
                    ) {
                        toggleSelection(item.videoCode)
                    } content: {
                        WatchHistoryRow(item: item)
                    }
                }
            } else {
                ForEach(visibleWatchHistory) { item in
                    NavigationLink(value: HanaRoute.video(item.videoCode)) {
                        WatchHistoryRow(item: item)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(item)
                        } label: {
                            Label("删除记录", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: delete)
            }
        }
    }

    private var isEditing: Bool {
        isSelectionModeActive
    }

    private var shouldShowToolbarActions: Bool {
        !visibleWatchHistory.isEmpty
    }

    private var visibleWatchHistory: [WatchHistoryRecord] {
        watchHistory.filter(\.isHistoryEligible)
    }

    private var areAllVisibleItemsSelected: Bool {
        let codes = Set(visibleWatchHistory.map(\.videoCode))
        return !codes.isEmpty && selectedVideoCodes.isSuperset(of: codes)
    }

    private func toggleEditMode() {
        withAnimation(.smooth(duration: 0.2)) {
            if isSelectionModeActive {
                isSelectionModeActive = false
                selectedVideoCodes.removeAll()
            } else {
                isSelectionModeActive = true
            }
        }
    }

    private func toggleSelection(_ videoCode: String) {
        if selectedVideoCodes.contains(videoCode) {
            selectedVideoCodes.remove(videoCode)
        } else {
            selectedVideoCodes.insert(videoCode)
        }
    }

    private func toggleAll() {
        let codes = Set(visibleWatchHistory.map(\.videoCode))
        if selectedVideoCodes.isSuperset(of: codes) {
            selectedVideoCodes.subtract(codes)
        } else {
            selectedVideoCodes.formUnion(codes)
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets where visibleWatchHistory.indices.contains(index) {
            modelContext.delete(visibleWatchHistory[index])
        }
        try? modelContext.save()
    }

    private func delete(_ item: WatchHistoryRecord) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func deleteSelected() {
        for item in visibleWatchHistory where selectedVideoCodes.contains(item.videoCode) {
            modelContext.delete(item)
        }
        selectedVideoCodes.removeAll()
        isSelectionModeActive = false
        try? modelContext.save()
    }

    private func clearAll() {
        for item in watchHistory {
            modelContext.delete(item)
        }
        selectedVideoCodes.removeAll()
        isSelectionModeActive = false
        try? modelContext.save()
    }
}

private struct WatchHistoryRow: View {
    let item: WatchHistoryRecord

    var body: some View {
        HanaVideoListRow(
            title: item.title,
            videoCode: item.videoCode,
            coverURL: coverURL,
            metadataItems: metadataItems,
            style: HanaVideoListRowStyle(verticalPadding: 2)
        )
    }

    private var coverURL: URL? {
        guard let coverURLString = item.coverURLString else { return nil }
        return URL(string: coverURLString)
    }

    private var metadataItems: [HanaVideoMetadataItem] {
        var items = [HanaVideoMetadataItem(item.videoCode, systemImage: "number")]
        if item.progress > 1 {
            items.append(HanaVideoMetadataItem(formatTime(item.progress), systemImage: "play.circle"))
        }
        items.append(HanaVideoMetadataItem(item.watchDate.hanaChineseDateTimeText))
        return items
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
