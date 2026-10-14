import Foundation

struct EventAPIEnvelope<Value: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: Value?
}

struct EventDetails: Decodable {
    let event: KitapiEvent
    let description: String?
    let instructions: [EventInstruction]
    let prizesDescription: String?
    let isActive: Bool
    let feeAmount: Decimal?
    let termsUrl: String?
    let privacyUrl: String?
    let mediaPolicyUrl: String?
    let images: [EventImage]
    let deadlineDate: String?
    let whatsappGroupLink: String?

    init(from decoder: any Decoder) throws {
        event = try KitapiEvent(from: decoder)
        let values = try decoder.container(keyedBy: CodingKeys.self)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        instructions = try values.decodeIfPresent([EventInstruction].self, forKey: .instructions) ?? []
        prizesDescription = try values.decodeIfPresent(String.self, forKey: .prizesDescription)
        isActive = try values.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        if let amount = try? values.decode(String.self, forKey: .feeAmount) {
            guard let decimal = Decimal(string: amount, locale: Locale(identifier: "en_US_POSIX")), decimal >= 0 else {
                throw DecodingError.dataCorruptedError(forKey: .feeAmount, in: values, debugDescription: "Invalid event fee")
            }
            feeAmount = decimal
        } else {
            feeAmount = try values.decodeIfPresent(Decimal.self, forKey: .feeAmount)
        }
        if let feeAmount, feeAmount < 0 {
            throw DecodingError.dataCorruptedError(forKey: .feeAmount, in: values, debugDescription: "Invalid event fee")
        }
        termsUrl = try values.decodeIfPresent(String.self, forKey: .termsUrl)
        privacyUrl = try values.decodeIfPresent(String.self, forKey: .privacyUrl)
        mediaPolicyUrl = try values.decodeIfPresent(String.self, forKey: .mediaPolicyUrl)
        deadlineDate = try values.decodeIfPresent(String.self, forKey: .deadlineDate)
        whatsappGroupLink = try values.decodeIfPresent(String.self, forKey: .whatsappGroupLink)
        let additional = try values.decodeIfPresent([EventImage].self, forKey: .images) ?? values.decodeIfPresent([EventImage].self, forKey: .imageUrls)
        let primary = (try? values.decode([EventImage].self, forKey: .imageUrl)) ?? event.imageUrl.map { [$0] } ?? []
        var seen = Set<String>()
        images = (primary + (additional ?? [])).filter { image in
            guard let url = image.url else { return false }
            return seen.insert(url).inserted
        }
    }

    @MainActor var acceptsRegistration: Bool { acceptsRegistration(at: Date()) }

    @MainActor func acceptsRegistration(at now: Date) -> Bool {
        guard isActive, event.status.lowercased() == "upcoming", let start = EventDateText.date(event.startDate), now < start else { return false }
        if let deadline = deadlineDate {
            guard let date = EventDateText.date(deadline) else { return false }
            // Date-only deadlines include their whole UTC calendar day.
            let close = deadline.contains("T") ? date : date.addingTimeInterval(86400)
            return now < close
        }
        return true
    }
    private enum CodingKeys: String, CodingKey {
        case description, instructions, prizesDescription, isActive, feeAmount, termsUrl, privacyUrl, mediaPolicyUrl, images, imageUrls, imageUrl, deadlineDate, whatsappGroupLink
    }
}

struct EventInstruction: Decodable {
    let step: Int
    let text: String
}

struct EventBatchSummary: Decodable {
    let id: String
    var name: String? = nil
    var feeAmount: EventMoney? = nil
    var feeCurrency: String? = nil
    var registrationDeadline: String? = nil
    var startDate: String? = nil
    var scheduleDescription: String? = nil
    var seatsAvailable: Int? = nil
    var isActive: Bool? = nil
    @MainActor func acceptsRegistration(at now: Date) -> Bool {
        guard isActive != false, seatsAvailable != 0 else { return false }
        if let startDate {
            guard let start = EventDateText.date(startDate), now < start else { return false }
        }
        if let registrationDeadline {
            guard let date = EventDateText.date(registrationDeadline) else { return false }
            return now < (registrationDeadline.contains("T") ? date : date.addingTimeInterval(86400))
        }
        return true
    }
}

struct EventParticipantPage: Decodable {
    let participants: [EventParticipation]
    let pagination: EventPagination
}

struct EventParticipation: Decodable, Identifiable {
    let id: String
    let childId: String?
    let status: String
    let child: EventParticipantChild?
    var whatsappGroupLink: String? = nil
    var event: EventPaidRegistration.Link? = nil
    var isRegistered: Bool { ["registered", "participant", "participated", "joined", "submitted", "winner", "confirmed"].contains(status.lowercased()) }
}

struct EventParticipantChild: Decodable {
    let name: String?
    let profilePicture: EventImage?
}

enum EventBookingKind { case unknown, free, paid }

enum EventLegalLinks {
    static func url(apiValue: String?, configurationKey: String, bundle: Bundle = .main) -> URL? {
        let value = apiValue ?? bundle.object(forInfoDictionaryKey: configurationKey) as? String
        guard let value, let url = URL(string: value), url.scheme?.lowercased() == "https", url.host != nil else { return nil }
        return url
    }
}
