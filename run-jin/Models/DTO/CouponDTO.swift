import Foundation

struct CouponDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let title: String
    let description: String
    let storeName: String
    let discountText: String
    let deepLink: String?
    let expiresAt: Date?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case storeName = "store_name"
        case discountText = "discount_text"
        case deepLink = "deep_link"
        case expiresAt = "expires_at"
        case imageUrl = "image_url"
    }
}
