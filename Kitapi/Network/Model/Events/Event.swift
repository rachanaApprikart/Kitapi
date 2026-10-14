import Foundation

enum EventListFilter: String, CaseIterable {
    case all, live, upcoming, completed

    var title: String { rawValue.capitalized }
    var apiStatus: String? { self == .all ? nil : rawValue }
}

struct EventListResponse: Decodable {
    let success: Bool
    let message: String?
    let data: EventPage?
}

struct EventPage: Decodable {
    let events: [KitapiEvent]
    let pagination: EventPagination
}

struct EventPagination: Decodable {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int
    let limit: Int
}

struct KitapiEvent: Decodable, Identifiable {
    let id: String
    let title: String
    let category: String?
    let status: String
    let startDate: String?
    let endDate: String?
    let imageUrl: EventImage?

    var displayStatus: String {
        switch status.lowercased() {
        case "live": return "Live"
        case "upcoming": return "Upcoming"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        default: return status.capitalized
        }
    }
}

struct EventImage: Decodable {
    let url: String?

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            url = string
        } else if let images = try? container.decode([EventImage].self) {
            url = images.compactMap(\.url).first
        } else {
            url = try decoder.container(keyedBy: CodingKeys.self).decodeIfPresent(String.self, forKey: .url)
        }
    }

    private enum CodingKeys: String, CodingKey { case url }
}

@MainActor
enum EventDateText {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()
    private static let parser = formatter("dd-MM-yyyy")
    private static let output = formatter("d MMM yyyy")
    private static let shortOutput = formatter("d MMM")
    private static let isoParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let isoSecondsParser = ISO8601DateFormatter()

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        formatter.isLenient = false
        return formatter
    }

    static func range(start: String?, end: String?) -> String {
        let first = date(start)
        let last = date(end)
        switch (first, last) {
        case let (first?, last?) where calendar.isDate(first, inSameDayAs: last): return display(first, includeYear: true)
        case let (first?, last?):
            if calendar.isDate(first, equalTo: last, toGranularity: .year) {
                return "\(display(first, includeYear: false)) – \(display(last, includeYear: false)) – \(calendar.component(.year, from: last))"
            }
            return "\(display(first, includeYear: true)) – \(display(last, includeYear: true))"
        case let (first?, nil): return display(first, includeYear: true)
        case let (nil, last?): return "Until \(display(last, includeYear: true))"
        default: return "Dates to be announced"
        }
    }

    private static func display(_ date: Date, includeYear: Bool) -> String {
        let day = calendar.component(.day, from: date)
        let suffix: String
        if (11...13).contains(day % 100) { suffix = "th" }
        else {
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        let text = (includeYear ? output : shortOutput).string(from: date)
        return text.replacingOccurrences(of: "^\\d+", with: "\(day)\(suffix)", options: .regularExpression)
    }

    static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        return parser.date(from: value) ?? isoParser.date(from: value) ?? isoSecondsParser.date(from: value)
    }
}
