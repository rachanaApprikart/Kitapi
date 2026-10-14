import Foundation

/// Owns event-list data, loading state, filters, and pagination.
@MainActor
final class EventListViewModel {
    private let service: any EventListing
    private var generation = UUID()
    private var currentPage = 0
    private var totalPages = 1
    private(set) var filter: EventListFilter = .all
    private(set) var events: [KitapiEvent] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var onChange: (() -> Void)?

    var canLoadMore: Bool { currentPage < totalPages && !isLoading }

    init(service: (any EventListing)? = nil) { self.service = service ?? EventService() }

    // No cleanup needs actor isolation; avoid the isolated-deinit back-deployment path.
    nonisolated deinit {}

    func reload(filter: EventListFilter? = nil) async {
        generation = UUID()
        if let filter { self.filter = filter }
        currentPage = 0
        totalPages = 1
        events = []
        isLoading = false
        await loadNextPage()
    }

    func loadNextPage() async {
        guard canLoadMore else { return }
        let requestGeneration = generation
        let requestedFilter = filter
        let page = currentPage + 1
        isLoading = true
        errorMessage = nil
        onChange?()
        defer {
            if requestGeneration == generation {
                isLoading = false
                onChange?()
            }
        }
        do {
            let result = try await service.fetchEvents(filter: filter, page: page)
            guard requestGeneration == generation, !Task.isCancelled else {
                EventAPILog.write("[EventList] IGNORED stale/cancelled response filter=\(requestedFilter.rawValue) page=\(page)")
                return
            }
            // Prevent malformed pagination from causing an endless load loop.
            guard result.pagination.currentPage == page else { throw EventServiceError.invalidResponse }
            var seen = Set(events.map(\.id))
            events += result.events.filter { seen.insert($0.id).inserted }
            currentPage = page
            totalPages = result.events.isEmpty ? page : max(page, result.pagination.totalPages)
        } catch is CancellationError {
            EventAPILog.write("[EventList] CANCELLED filter=\(requestedFilter.rawValue) page=\(page)")
        } catch {
            guard requestGeneration == generation, !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            EventAPILog.write("[EventList] LOAD FAILED filter=\(requestedFilter.rawValue) page=\(page) reason=\(EventAPILog.errorSummary(error))")
        }
    }
}
