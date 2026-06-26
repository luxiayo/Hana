import SwiftUI

struct HKeyframeManagementScreen: View {
    @State private var records: [HKeyframeRecordModel] = []
    @State private var query = ""
    @State private var toastMessage: HanaToastMessage?
    @State private var alertMessage: HanaAlertMessage?

    private let persistence = JSONPersistenceManager.shared

    private var visibleRecords: [HKeyframeRecordModel] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return records }
        return records.filter {
            $0.title.localizedStandardContains(text)
                || $0.videoCode.localizedStandardContains(text)
                || ($0.groupTitle?.localizedStandardContains(text) ?? false)
        }
    }

    var body: some View {
        content
            .navigationTitle("HKeyframes")
            .searchable(text: $query, prompt: "标题或番号")
            .hanaToast($toastMessage)
            .hanaFeedbackAlert($alertMessage)
            .task {
                records = persistence.loadHKeyframeRecords()
            }
    }

    @ViewBuilder
    private var content: some View {
        if records.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bookmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("暂无本地 HKeyframes")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("从剪贴板导入后会显示在这里。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                importButton
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if visibleRecords.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("没有符合条件的 HKeyframes")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            hKeyframeList
        }
    }

    private var hKeyframeList: some View {
        List {
            Section {
                importButton
            }

            Section("本地 HKeyframes") {
                recordRows
            }
        }
    }

    private var importButton: some View {
        Button {
            importFromPasteboard()
        } label: {
            Label("从剪贴板导入", systemImage: "doc.on.clipboard")
        }
    }

    private var recordRows: some View {
        ForEach(visibleRecords) { record in
            NavigationLink {
                HKeyframeRecordDetailScreen(record: record, onDelete: { deletedRecord in
                    records = persistence.loadHKeyframeRecords()
                })
            } label: {
                HKeyframeRecordRow(record: record)
            }
        }
        .onDelete(perform: delete)
    }

    private func importFromPasteboard() {
        do {
            guard let text = HanaPasteboard.string else {
                throw HanaHKeyframeImportError.invalidShareText
            }
            let record = try HanaHKeyframeLibrary.decodeShareText(text)
            let videoCode = record.videoCode

            let existingRecords = persistence.loadHKeyframeRecords()
            for existing in existingRecords where existing.videoCode == videoCode {
                persistence.deleteHKeyframeRecord(existing)
            }

            persistence.insertHKeyframeRecord(record)
            records = persistence.loadHKeyframeRecords()
            toastMessage = .success("已导入 \(record.title)")
        } catch {
            alertMessage = .error(error.localizedDescription)
        }
    }

    private func delete(_ offsets: IndexSet) {
        for offset in offsets {
            persistence.deleteHKeyframeRecord(visibleRecords[offset])
        }
        records = persistence.loadHKeyframeRecords()
    }
}

private struct HKeyframeRecordRow: View {
    let record: HKeyframeRecordModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("\(record.keyframes.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Label(record.videoCode, systemImage: "number")
                if let groupTitle = record.groupTitle {
                    Text(groupTitle)
                }
                if let author = record.author {
                    Text(author)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }
}

struct HKeyframeRecordDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    let record: HKeyframeRecordModel
    let onDelete: (HKeyframeRecordModel) -> Void
    @State private var toastMessage: HanaToastMessage?
    @State private var alertMessage: HanaAlertMessage?
    @State private var editingKeyframe: HKeyframeEntry?
    @State private var isManualAddPresented = false

    private let persistence = JSONPersistenceManager.shared

    var body: some View {
        detailContent
            .navigationTitle("HKeyframes")
            .hanaToast($toastMessage)
            .hanaFeedbackAlert($alertMessage)
            .onDisappear {
                persistence.insertHKeyframeRecord(record)
            }
            .sheet(item: $editingKeyframe) { keyframe in
                HKeyframeEditSheet(
                    title: "编辑关键帧",
                    initialPositionMilliseconds: keyframe.positionMilliseconds,
                    initialPrompt: keyframe.prompt ?? ""
                ) { updated in
                    record.replace(keyframe, with: updated)
                    persistence.insertHKeyframeRecord(record)
                }
            }
            .sheet(isPresented: $isManualAddPresented) {
                HKeyframeEditSheet(
                    title: "添加关键帧",
                    initialPositionMilliseconds: 0,
                    initialPrompt: ""
                ) { keyframe in
                    record.append(keyframe)
                    persistence.insertHKeyframeRecord(record)
                }
            }
    }

    @ViewBuilder
    private var detailContent: some View {
#if os(macOS)
        macOSDetailContent
#else
        detailForm
#endif
    }

    private var detailForm: some View {
        Form {
            Section("信息") {
                LabeledContent("标题", value: record.title)
                LabeledContent("系列", value: record.groupTitle ?? "")
                LabeledContent("集数", value: "\(record.episode)")
                LabeledContent("番号", value: record.videoCode)
            }

            Section("关键帧") {
                if record.keyframes.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bookmark.slash")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("暂无关键帧")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(record.keyframes) { keyframe in
                        HStack {
                            Button {
                                editingKeyframe = keyframe
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatTime(keyframe.seconds))
                                        .font(.headline)
                                    if let prompt = keyframe.prompt {
                                        Text(prompt)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                editingKeyframe = keyframe
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                record.remove(keyframe)
                                persistence.insertHKeyframeRecord(record)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                Button {
                    isManualAddPresented = true
                } label: {
                    Label("手动添加关键帧", systemImage: "plus.circle")
                }
            }

            Section {
                Button {
                    copyShareText()
                } label: {
                    Label("复制分享文本", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    deleteRecord()
                } label: {
                    Label("删除整组", systemImage: "trash")
                }
            }
        }
    }

#if os(macOS)
    private var macOSDetailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                macOSInfoSection

                Divider()

                macOSKeyframeSection

                Divider()

                macOSActionRow
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var macOSInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("信息")
                .font(.headline)

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    macOSFieldLabel("标题:")
                    Text(record.title)
                        .frame(maxWidth: 520, alignment: .leading)
                }

                GridRow {
                    macOSFieldLabel("系列:")
                    Text(record.groupTitle ?? "")
                        .frame(maxWidth: 360, alignment: .leading)
                }

                GridRow {
                    macOSFieldLabel("集数:")
                    Text("\(record.episode)")
                        .frame(width: 90, alignment: .leading)
                }

                GridRow {
                    macOSFieldLabel("番号:")
                    Text(record.videoCode)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var macOSKeyframeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("关键帧")
                    .font(.headline)
                Spacer()
                Button {
                    isManualAddPresented = true
                } label: {
                    Label("添加关键帧", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }

            if record.keyframes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("暂无关键帧")
                        .foregroundStyle(.secondary)
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
            } else {
                macOSKeyframeRows
            }
        }
    }

    private var macOSKeyframeRows: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("时间")
                    .frame(width: 120, alignment: .leading)
                Text("提示")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("操作")
                    .frame(width: 96, alignment: .leading)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ForEach(record.keyframes) { keyframe in
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Text(formatTime(keyframe.seconds))
                        .font(.body.monospacedDigit())
                        .frame(width: 120, alignment: .leading)

                    Text(keyframe.prompt ?? "无")
                        .foregroundStyle(keyframe.prompt == nil ? .secondary : .primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Button {
                            editingKeyframe = keyframe
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        .help("编辑")

                        Button(role: .destructive) {
                            delete(keyframe)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("删除")
                    }
                    .frame(width: 96, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

                if keyframe.id != record.keyframes.last?.id {
                    Divider()
                }
            }
        }
        .overlay(alignment: .top) {
            Divider()
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var macOSActionRow: some View {
        HStack {
            Button {
                copyShareText()
            } label: {
                Label("复制分享文本", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button(role: .destructive) {
                deleteRecord()
            } label: {
                Label("删除整组", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    private func macOSFieldLabel(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(width: 64, alignment: .trailing)
    }
#endif

    private func copyShareText() {
        do {
            HanaPasteboard.string = try HanaHKeyframeLibrary.shareText(for: record)
            toastMessage = .success("已复制到剪贴板")
        } catch {
            alertMessage = .error(error.localizedDescription)
        }
    }

    private func delete(_ keyframe: HKeyframeEntry) {
        record.remove(keyframe)
        persistence.insertHKeyframeRecord(record)
    }

    private func deleteRecord() {
        persistence.deleteHKeyframeRecord(record)
        onDelete(record)
        dismiss()
    }
}

