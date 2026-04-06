import CoreLocation
import Foundation

protocol H3ServiceProtocol: Sendable {
    /// 座標からH3インデックス文字列を取得（resolution 10）
    func h3Index(for coordinate: CLLocationCoordinate2D) throws -> String

    /// H3インデックスから6頂点座標を取得（地図描画用）
    func boundary(for h3Index: String) throws -> [CLLocationCoordinate2D]

    /// 座標リストから重複排除されたH3インデックスリストを取得
    func h3Indices(for coordinates: [CLLocationCoordinate2D]) throws -> [String]

    /// k-ring: 指定セルの周辺セルを取得
    func kRing(for h3Index: String, distance: Int) throws -> [String]
}
