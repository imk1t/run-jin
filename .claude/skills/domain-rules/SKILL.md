---
name: domain-rules
description: Run-Jin のドメイン固有ビジネスルール（territory 獲得・上書きの距離判定、privacy zone フィルタ、H3 ヘックスグリッド利用、ラン送信の idempotency、HealthKit + GPS 並行取得）を扱うときに使用。Territory / Run / Privacy / H3 関連のコード（`TerritoryCaptureEngine`, `RunSessionService`, `RunSyncService`, `submit-run` Edge Function 等）を読み書きするとき発動。
---

# Domain Rules — Run-Jin 固有のビジネスロジック

> Run-Jin は走行軌跡を H3 ヘックスセルに変換して陣地化するゲーム。本 Skill は「**コードを読んだだけでは見抜きにくいビジネス意図**」を集約する。

## Hex Grid (H3)
- 解像度: **resolution 10**（セル平均エッジ ~65m、面積 ~50m × ~50m スケール）固定
- インデックス表現: `String`（例: `8a2a1072b59ffff`、頭2文字 `8a` が res10 の証）
- 計算ライブラリ: **SwiftyH3**（iOS 側）
- 計算位置: `H3Service`（`H3ServiceProtocol`）。重い処理は `nonisolated` 関数で提供しメインスレッドをブロックしない

## Territory Capture（iOS 側 = client-side preview）
`Services/TerritoryCaptureEngine.swift` がラン直後に **楽観的な capture プレビュー**を計算して UI に即時表示する。

- **走行ライン → セル列の細分化**: 区間を `segmentSamplingMeters = 20.0` (m) でサンプリングし、H3 res10 のエッジ長 (~65m) を必ずまたぐようにする → 走行ラインが貫通するすべてのセルを欠落なく拾える
- **セルごとの距離計上**: セル切替時に直前の累積距離をそのセルへ加算
- **上書き判定（client preview）**: 他人セルへの上書きは
  ```
  新走行距離 > 既存距離 × overrideMultiplier (= 1.5)
  ```
  を満たすときのみ。自分のセルはスキップ
- 結果は `CaptureResult { capturedCells, overriddenCells, failedCells }`

## Territory Capture（サーバ側 = source of truth）
`supabase/functions/submit-run/` が **最終確定**を行う。iOS の preview とロジックが一部異なる点に注意:

- **Landmark bonus**: ランドマーク半径 `LANDMARK_BONUS_RADIUS_METERS = 200m` 内のセルは `bonus_multiplier` を距離に乗じる（同セル複数該当時は最大値）
- **未所有セル**: 即獲得
- **自分所有セル**: 距離を加算
- **他人所有セル**: `effectiveDistance > existingCell.total_distance_meters * 0.5` のときに上書き（**iOS preview の 1.5× とは別パラメータ**）
- 各上書きは `territory_captures` に履歴を残す
- セッション全体で `cells_captured` / `cells_overridden` を集計し `run_sessions` に書き戻す

> ⚠️ iOS preview と server 確定で**閾値が異なる**ため、UI 上の楽観表示と最終結果に差分が出ることがある。両者を変更する際は必ず両側を更新すること。

## Run Submission Idempotency
- iOS 側で UUID を生成し `idempotency_key` として保存・送信
- Edge Function は受信時に既存 `run_sessions.idempotency_key` を検索 → ヒットすれば既存 `session_id` を返却（重複投稿防止）
- 再送・リトライ時の二重計上を防ぐ

## Privacy Zone
- ユーザー定義の自宅 / 職場周辺セルは API response から除外して返す
- 位置情報の漏洩防止（個人特定リスクを最小化）
- 新規 API 追加時は **必ず privacy zone フィルタを適用**

## HealthKit + GPS 並行取得
`Services/RunSessionService.swift` がラン中の状態を統合管理:
- `LocationService.locationStream: AsyncStream<CLLocation>` から GPS
- `HealthKitService.heartRateStream` から心拍
- 2 つを `async let` または `Task` で並行 await し、`RunSession` (SwiftData `@Model`) に書き込む
- バッテリー: GPS は `distanceFilter` を効かせ、不要時は停止

## ラン完了 → 同期フロー
```
1. RunSessionService が走行終了を検知
2. RunCompletionService が territory preview を計算（TerritoryCaptureEngine）
3. UI で結果アニメーション表示
4. RunSyncService が submit-run Edge Function を idempotency_key 付きで叩く
5. サーバ確定結果でローカル状態を補正
```

新規ドメイン機能を追加する際は、この **「楽観 preview → idempotency 付き確定 → 補正」** パターンを踏襲する。
