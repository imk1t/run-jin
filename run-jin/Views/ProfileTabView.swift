import SwiftUI
import PhotosUI

struct ProfileTabView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        Form {
            avatarSection
            nameSection
            locationSection
            statsSection
            settingsSection
            accountSection
        }
        .navigationTitle("プロフィール")
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .onChange(of: viewModel.selectedPhotoItem) {
            Task {
                await viewModel.handlePhotoSelection()
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    avatarImage

                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images
                    ) {
                        Text("写真を変更")
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let urlString = viewModel.avatarURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    avatarPlaceholder
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundStyle(.gray)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        Section("表示名") {
            TextField("表示名を入力", text: $viewModel.displayName)
                .textContentType(.name)
        }
    }

    // MARK: - Location Section

    private var locationSection: some View {
        Section("所在地") {
            Picker("都道府県", selection: $viewModel.selectedPrefectureCode) {
                Text("未選択").tag(nil as Int?)
                ForEach(PrefectureData.prefectures) { prefecture in
                    Text(prefecture.name).tag(prefecture.id as Int?)
                }
            }
            .onChange(of: viewModel.selectedPrefectureCode) {
                // 都道府県変更時は市区町村をリセット
                viewModel.selectedMunicipalityCode = nil
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Section("統計") {
            HStack {
                Label("走行距離", systemImage: "figure.run")
                Spacer()
                Text("\(viewModel.totalDistanceKm) km")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("占領セル", systemImage: "hexagon.fill")
                Spacer()
                Text("\(viewModel.totalCellsOwned)")
                    .foregroundStyle(.secondary)
            }
            if viewModel.isPremium {
                HStack {
                    Label("プレミアム", systemImage: "crown.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("有効")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        Section("設定") {
            NavigationLink {
                AnonymousModeView()
            } label: {
                Label("匿名モード", systemImage: "eye.slash.fill")
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            Button {
                Task {
                    await viewModel.saveProfile()
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("保存")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isSaving)

            Button(role: .destructive) {
                Task {
                    await viewModel.signOut()
                }
            } label: {
                HStack {
                    Spacer()
                    Text("ログアウト")
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
}
