---
name: swift-architecture
description: Swift / iOS コード（SwiftUI Views, @Observable ViewModels, Services, Repositories, SwiftData @Model, run-jinTests/run-jinUITests）を書く・編集するときに使用。レイヤード MVVM+Repository アーキテクチャ、DependencyContainer による DI パターン、Domain/DTO 分離、strict concurrency（@MainActor / nonisolated init / AsyncStream）、SwiftUI/SwiftData 規約、String Catalogs ローカライズ、Swift Testing、コード品質ルールを提供。
---

# Swift / iOS Architecture & Conventions

## レイヤー構成
```
View (SwiftUI)
  ↓ binds
ViewModel (@Observable, @MainActor)
  ↓ calls
Repository (protocol)
  ↓ uses
Service (protocol) / SwiftData / Supabase
```

- **View に業務ロジックを置かない** — 状態と分岐は ViewModel に集約
- **新規 Service / Repository は必ず Protocol を切る**（`SomeServiceProtocol: Sendable`）。テスト時に Mock 差し替え可能にするため
- 依存はコンストラクタ注入。`DependencyContainer` 経由で生成

## DependencyContainer パターン
全 Service は `App/DependencyContainer.swift` の **シングルトン + lazy 初期化**で管理。

```swift
@Observable
final class DependencyContainer: @unchecked Sendable {
    static let shared = DependencyContainer()

    private var _someService: SomeServiceProtocol?
    var someService: SomeServiceProtocol {
        if _someService == nil { _someService = SomeService() }
        return _someService!
    }
}
```

- ステートレス Service: `var` プロパティで lazy 提供
- `ModelContext` を要する Service（RunSessionService 等）: `@MainActor func` ファクトリで提供
- 新 Service 追加時は (1) Protocol 定義 → (2) 実装 → (3) Container にプロパティ追加 → (4) View / ViewModel から `DependencyContainer.shared.xxx` で取得

## Models: Domain vs DTO 分離
| 配置 | 役割 | 例 |
|------|------|-----|
| `Models/Domain/` | SwiftData `@Model`、ローカル永続化対象 | `RunSession`, `Territory` |
| `Models/DTO/` | `Codable`、Supabase との JSON 入出力専用 | `SubmitRunDTO` |

- 両者を混ぜない。マッピングは Repository 層で行う

## Concurrency（strict concurrency 有効）
- **ViewModels** は `@MainActor @Observable` がデフォルト
- ViewModel の `init` は `nonisolated` を明示し、DI 注入を可能にする
- 重い計算（H3、GPS 後処理）は `nonisolated` 関数または専用 Actor へ
- リアクティブストリームは **Combine ではなく `AsyncStream`**
  - 例: `LocationService.locationStream: AsyncStream<CLLocation>`、`AuthService.authStateStream`

## SwiftUI & SwiftData
- ViewModels は `@Observable`（`ObservableObject` は使わない）
- View 内の SwiftData 読み込みは `@Query`
- 画面遷移は `NavigationStack` + 型付き `NavigationPath`
- Min deployment target: **iOS 17**

## Localization
- **必須**: 全 UI 文字列は String Catalogs (`Localizable.xcstrings`)
- 日本語が主言語（ソース上の文字列）、英語がローカライズ対象
- 直接ハードコード禁止
- `Text("文字列")` / `.navigationTitle("文字列")` は自動でカタログキー化
- Swift コード内では `String(localized: "文字列")`
- **カスタム View / 関数のパラメータ**: ユーザー向け文字列は `LocalizedStringKey` 型に（`String` 型だと `Text(param)` でローカライズされない）
- **配列/タプル**: UI 表示用文字列を入れる場合も `LocalizedStringKey` または `String(localized:)` 初期化
- **新規追加時**: ビルドで Xcode が自動抽出するが、英語翻訳は `Localizable.xcstrings` に手動追加
- `fatalError` 等の開発者向けメッセージはローカライズ不要

## Code Quality
- **Force unwrap (`!`) 禁止** — やむを得ない場合は理由コメント必須
- **エラーハンドリング必須** — silent failure（空 `catch {}`）禁止
- **ハードコードシークレット禁止** — `Bundle.main` 経由で `Config.xcconfig` から取得

## Testing
- フレームワーク: **Swift Testing**（`import Testing`、`@Test`、`#expect`）
- 配置: `run-jinTests/<TargetName>Tests.swift`
- 対象: Service / Repository / ViewModel のロジック
- エッジケース: オフライン、空データ、並行アクセスを意識
