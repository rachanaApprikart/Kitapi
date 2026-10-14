import Foundation

struct EventMoney: Decodable, Equatable {
    let value: Decimal
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            guard string.range(of: "^[0-9]+(\\.[0-9]+)?$", options: .regularExpression) != nil,
                  let decimal = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) else { throw EventServiceError.invalidResponse }
            value = decimal
        } else { value = try container.decode(Decimal.self) }
        guard value >= 0 else { throw EventServiceError.invalidResponse }
    }
    func paise(currency: String) throws -> Int {
        let number = NSDecimalNumber(decimal: value * 100)
        guard currency == "INR", number.compare(NSDecimalNumber.zero) == .orderedDescending,
              number.compare(NSDecimalNumber(value: Int.max)) == .orderedAscending,
              number.decimalValue == Decimal(number.intValue) else { throw EventServiceError.server("Invalid payment amount or unsupported currency.") }
        return number.intValue
    }
    var display: String { "₹" + NSDecimalNumber(decimal: value).stringValue }
}

struct EventPaidRegistration: Decodable, Identifiable {
    let id: String
    var childId: String? = nil
    let status: String
    var eventBatchId: String? = nil
    var eventId: String? = nil
    var amount: EventMoney? = nil
    var feeAmount: EventMoney? = nil
    var paidAt: String? = nil
    var confirmedAt: String? = nil
    var amountPayable: EventMoney? = nil
    var registrationCode: String? = nil
    var child: Child? = nil
    var whatsappGroupLink: String? = nil
    var batch: Link? = nil
    var event: Link? = nil
    struct Link: Decodable { var id: String?; var whatsappGroupLink: String? }
    struct Child: Decodable { let id: String }
    var ownerChildID: String? { childId ?? child?.id }
    var isConfirmed: Bool { status.lowercased() == "confirmed" }
    var groupURL: URL? { isConfirmed ? EventGroupLink.url(batch?.whatsappGroupLink ?? event?.whatsappGroupLink ?? whatsappGroupLink) : nil }
}

struct EventRegistrationPage: Decodable {
    let registrations: [EventPaidRegistration]
    let pagination: EventPagination
}

struct EventPaymentOrder: Decodable {
    let registrationId: String
    let razorpayOrderId: String
    let keyId: String
    let amount: EventMoney
    let currency: String
}

struct EventPaymentProof: Encodable {
    let razorpayOrderId: String
    let razorpayPaymentId: String
    let razorpaySignature: String
}

enum EventGroupLink {
    static func url(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), url.scheme == "https",
              url.host?.lowercased() == "chat.whatsapp.com", url.user == nil, url.password == nil,
              url.path.count > 1 else { return nil }
        return url
    }
}
