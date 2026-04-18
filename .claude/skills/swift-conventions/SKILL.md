---
name: swift-conventions
description: Swift/iOS のコードを書く・編集するとき（SwiftUI Views、@Observable ViewModels、Services、Repositories、SwiftData @Model、run-jinTests/run-jinUITests）に使用。MVVM+Repository アーキテクチャ、strict concurrency、String Catalogs ローカライゼーション、force unwrap 禁止、Config.xcconfig 経由のシークレット参照などの規約を提供。
---

# Swift / iOS Coding Conventions

## Architecture Pattern
- **MVVM + Repository + Service Layer**
- Flow: `View (SwiftUI) → ViewModel (@Observable) → Repository (protocol) → Service / SwiftData / Supabase`
- No business logic in Views — delegate to ViewModels
- New services must be protocol-based and injectable via DependencyContainer

## Concurrency
- Strict concurrency is enabled. ViewModels are `@MainActor` by default.
- Use `nonisolated` or custom actors for background work (e.g., H3 computation, GPS processing).
- Use `AsyncStream` for reactive data (not Combine unless necessary).

## SwiftUI & SwiftData
- Use `@Observable` (not `ObservableObject`) for ViewModels
- Use `@Query` for SwiftData reads in Views
- Prefer `NavigationStack` with typed `NavigationPath`
- Minimum deployment target: iOS 17

## Localization
- **必須**: 全てのUI文字列はString Catalogs (`Localizable.xcstrings`) を使用すること
- 日本語が主言語（ソースコード上の文字列）、英語がローカライズ対象
- ソースコードに直接ユーザー向け文字列をハードコードしない
- SwiftUIの `Text("文字列")` や `.navigationTitle("文字列")` は自動的にString Catalogsのキーとなる
- Swift コード内では `String(localized: "文字列")` を使用する
- fatalError等の開発者向けメッセージはローカライズ不要
- **カスタムView/関数のパラメータ**: ユーザー向け文字列を受け取るパラメータは `LocalizedStringKey` 型にする（`String` 型だと `Text(param)` でローカライズされない）
- **新しい文字列を追加した場合**: `Localizable.xcstrings` に英語翻訳を必ず追加すること。ビルド後にXcodeが自動抽出するが、翻訳は手動で追加が必要
- **配列/タプルの文字列**: UI表示用文字列を配列に格納する場合は `LocalizedStringKey` 型を使うか、`String(localized:)` で初期化する

## Code Quality
- No force unwraps (`!`) unless justified with a comment
- Error handling present — no silent failures
- No hardcoded secrets or API keys — use `Config.xcconfig` values via `Bundle.main`
