import MapKit
import SwiftData
import SwiftUI

struct PrivacyZoneListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PrivacyZoneViewModel?
    @State private var showEditor = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("プライバシーゾーン")
        .onAppear {
            if viewModel == nil {
                viewModel = PrivacyZoneViewModel(
                    repository: PrivacyZoneRepository(),
                    modelContext: modelContext
                )
            }
        }
        .task {
            await viewModel?.loadZones()
        }
    }

    @ViewBuilder
    private func content(viewModel: PrivacyZoneViewModel) -> some View {
        List {
            Section {
                ForEach(viewModel.zones, id: \.id) { zone in
                    zoneRow(zone, viewModel: viewModel)
                }
            } header: {
                Text("登録済みゾーン（\(viewModel.zones.count)/\(PrivacyZoneViewModel.maxZones)）")
            } footer: {
                Text("プライバシーゾーン内のランニングデータは他のユーザーに公開されません。自宅や職場などを登録してください。")
            }

            if viewModel.canAddZone {
                Section {
                    Button {
                        viewModel.prepareNewZone()
                        showEditor = true
                    } label: {
                        Label("ゾーンを追加", systemImage: "plus.circle.fill")
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                PrivacyZoneEditorView(viewModel: viewModel) {
                    showEditor = false
                }
            }
        }
        .alert("このゾーンを削除しますか？", isPresented: $showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                Task {
                    await viewModel.deleteZone()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("プライバシーゾーンを削除すると、この範囲のランニングデータが他のユーザーに公開される可能性があります。")
        }
        .onChange(of: viewModel.showDeleteConfirmation) { _, newValue in
            showDeleteConfirmation = newValue
        }
    }

    @ViewBuilder
    private func zoneRow(_ zone: PrivacyZone, viewModel: PrivacyZoneViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.label.isEmpty ? String(localized: "名称未設定") : zone.label)
                    .font(.headline)
                Text("半径 \(zone.radiusMeters)m")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.prepareEditZone(zone)
                showEditor = true
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.confirmDelete(zone)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Editor View

struct PrivacyZoneEditorView: View {
    @Bindable var viewModel: PrivacyZoneViewModel
    let onDismiss: () -> Void

    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            mapSection

            settingsSection
        }
        .navigationTitle(viewModel.editingZone == nil ? "ゾーンを追加" : "ゾーンを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    onDismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    isSaving = true
                    Task {
                        await viewModel.saveZone()
                        isSaving = false
                        if viewModel.errorMessage == nil {
                            onDismiss()
                        }
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            mapCameraPosition = viewModel.editCameraPosition
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        ZStack {
            Map(position: $mapCameraPosition) {
                // 半径を示す円オーバーレイ
                MapCircle(
                    center: viewModel.editCoordinate,
                    radius: viewModel.editRadius
                )
                .foregroundStyle(.blue.opacity(0.15))
                .stroke(.blue.opacity(0.5), lineWidth: 2)

                // 中心ピン
                Annotation("", coordinate: viewModel.editCoordinate) {
                    Image(systemName: "shield.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange(frequency: .continuous) { context in
                viewModel.editCoordinate = context.camera.centerCoordinate
            }

            // ドラッグ用ヒント
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("地図をドラッグして中心を設定")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(.bottom, 8)
            }
        }
        .frame(height: 320)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Form {
            Section("ゾーン名") {
                TextField("自宅、職場など", text: $viewModel.editLabel)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("半径")
                        Spacer()
                        Text("\(Int(viewModel.editRadius))m")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(
                        value: $viewModel.editRadius,
                        in: PrivacyZoneViewModel.minRadius...PrivacyZoneViewModel.maxRadius,
                        step: 50
                    )
                }
            } header: {
                Text("範囲設定")
            } footer: {
                Text("この範囲内のランニングデータは非公開になります。")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
    }
}

#Preview("List") {
    NavigationStack {
        PrivacyZoneListView()
    }
    .modelContainer(for: PrivacyZone.self, inMemory: true)
}
