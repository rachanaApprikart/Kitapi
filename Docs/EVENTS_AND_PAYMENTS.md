# Events and payments: developer and AI guide

Last checked against the working tree: **15 October 2026**.

This document describes the implemented iOS flow, not a promise of backend behavior or production certification. Source and tests take precedence if they change. Update this guide whenever a route, payload, state transition, or UI rule changes.

## Quick start

- Platform: UIKit, iOS 16+, modern Swift. This feature already uses ViewModels; retain them.
- Events and payments use the existing **`APIClient` in `NetworkService.swift`**. Do not recreate `EndpointClient` or another HTTP client.
- Keep routes, methods, query parameters, and JSON bodies in `EventEndpoint` or `PaymentEndpoint`, not controllers or services.
- The active child comes from `ChildManager.shared.selectedChild`. The batch comes from the event's batch API. They are different entities.
- Free registration and paid registration are separate APIs and models.
- A Razorpay success callback is **not** registration confirmation. Only backend `status == "confirmed"` unlocks paid success/group access.
- No optional grade/school form or extra payment-review alert. A single eligible batch is automatic; multiple eligible batches require selection. Successful registration/order API calls lead directly to checkout.
- Registration/payment failures use the existing SwiftMessages wrapper, `MessageManager.shared.show(message:type:)`, once per failure. Do not put raw JSON or persistent registration errors in the footer.
- Participation is intentionally hidden. Do not expose it without a product requirement.
- Use fake tokens and `URLProtocol` mocks in tests. Do not make live registrations, payment orders, charges, or group joins to verify a code change.

## Contents

1. [Architecture and file map](#architecture-and-file-map)
2. [API contracts](#api-contracts)
3. [List and details loading](#list-and-details-loading)
4. [Free registration](#free-registration)
5. [Paid registration and checkout](#paid-registration-and-checkout)
6. [Registration availability and footer](#registration-availability-and-footer)
7. [Identity, persistence, and WhatsApp](#identity-persistence-and-whatsapp)
8. [UI rules and past regressions](#ui-rules-and-past-regressions)
9. [Errors, authentication, and logs](#errors-authentication-and-logs)
10. [Making changes safely](#making-changes-safely)
11. [Tests and release checks](#tests-and-release-checks)
12. [Known limitations and troubleshooting](#known-limitations-and-troubleshooting)

## Architecture and file map

```text
ViewController -> ViewModel -> feature service -> EventEndpoint / PaymentEndpoint
                                                 |
                                                 v
                                        APIClient.execute(...)
                                        in NetworkService.swift
                                                 |
                                                 v
                                        performJSONRequest(...)
                                                 |
                                                 v
                                        injected URLSession

Existing APIClient.callAPIWithRawData / callAPIWithFormData
                         -> the same performJSONRequest(...)

Paid UI -> EventCheckout -> Razorpay SDK -> EventPaymentProof
                                               |
                                               v
                           ViewModel -> service -> backend verification
```

Endpoint definitions describe requests; services return domain models; ViewModels own business state; controllers render and present. `APIClientProtocol` is an injectable interface, not a second networking implementation.

Paths below are relative to the repository root. Links are relative to this document.

| Responsibility | Source |
| --- | --- |
| Existing shared HTTP client, JSON/multipart compatibility, authentication, decoding | [NetworkService.swift](../Kitapi/Network/NetworkService.swift) |
| Client injection contract | [APIClientProtocol.swift](../Kitapi/Network/APIClientProtocol.swift) |
| Endpoint contract, defaults, identifier validation | [APIEndpoint.swift](../Kitapi/Network/Endpoints/APIEndpoint.swift) |
| Event routes and free-registration payload | [EventEndpoint.swift](../Kitapi/Network/Endpoints/EventEndpoint.swift) |
| Paid-registration, history, order, verification routes/payloads | [PaymentEndpoint.swift](../Kitapi/Network/Endpoints/PaymentEndpoint.swift) |
| Event-list service and `EventServiceError` | [EventService.swift](../Kitapi/Network/Services/EventService.swift) |
| Details, batches, free participations service | [EventDetailsService.swift](../Kitapi/Network/Services/EventDetailsService.swift) |
| Paid-registration service and paginated history filtering | [EventPaymentService.swift](../Kitapi/Network/Services/EventPaymentService.swift) |
| Sanitized API diagnostics | [EventAPILog.swift](../Kitapi/Network/Services/EventAPILog.swift) |
| Event list, pagination, image decoding, date display | [Event.swift](../Kitapi/Network/Model/Events/Event.swift) |
| Details, steps, batch availability, free participation, policy URL validation | [EventDetails.swift](../Kitapi/Network/Model/Events/EventDetails.swift) |
| Money conversion, paid registration/order/proof, group-link validation | [EventPayment.swift](../Kitapi/Network/Model/Events/EventPayment.swift) |
| List UI, navigation, child selection, refresh/load-more rendering | [EventListViewController.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventList/EventListViewController.swift) |
| List state, generation guards, deduplication | [EventListViewModel.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventList/EventListViewModel.swift) |
| List cards, image loading, category/status appearance, shared filter tab | [EventCardCell.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventList/EventCardCell.swift), [EventCardStyle.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventList/EventCardStyle.swift), [EventStatusRibbon.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventList/EventStatusRibbon.swift), [EventFilterTab.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventList/EventFilterTab.swift) |
| Details controller, footer, collapsing navigation, table/gallery delegates | [EventDetailsViewController.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventDetailsViewController.swift) |
| Programmatic details layout and legal-link text | [EventDetails+Constraints.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventDetails+Constraints.swift) |
| Details state, classification, registration, payment reconciliation | [EventDetailsViewModel.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventDetailsViewModel.swift) |
| Batch selection, direct checkout, success/group/error presentation | [EventDetails+Payment.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventDetails+Payment.swift) |
| SDK adapter and `EventCheckoutPresenting` injection point | [EventCheckout.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventCheckout.swift) |
| Details text cards and gallery image cells | [EventDetailsCardCell.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventDetailsCardCell.swift), [EventHeroImageCell.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventHeroImageCell.swift) |
| Confirmed-registration modal | [EventRegistrationSuccessViewController.swift](../Kitapi/Core/Tabbar/ParentTab/Events/EventDetails/EventRegistrationSuccessViewController.swift) |
| Storyboard factory and scenes | [VCManager.swift](../Kitapi/Helpers/VCManager.swift), [KitapiTab.storyboard](../Kitapi/Core/StoryBoards/KitapiTab.storyboard) |
| Runtime child, persisted child-mode session, child model | [ChildManager.swift](../Kitapi/Helpers/ChildManager.swift), [ChildSessionManager.swift](../Kitapi/Helpers/ChildSessionManager.swift), [Children.swift](../Kitapi/Network/Model/Child/Children.swift) |
| Parent token/defaults and policy constants | [AppUserDefaults.swift](../Kitapi/Helpers/AppUserDefaults.swift), [AppConstants.swift](../Kitapi/Helpers/AppConstants.swift) |
| Typography, palette, existing SwiftMessages wrapper | [KitapiFonts.swift](../Kitapi/Helpers/KitapiFonts.swift), [ColorPalette.swift](../Kitapi/Helpers/ColorPalette.swift), [SwiftMessages.swift](../Kitapi/Helpers/SwiftMessages.swift) |

## API contracts

### Host, authentication, and envelope

`BASE_URL` is currently declared in [RegistrationService.swift](../Kitapi/Network/Services/RegistrationService.swift): `https://kidswallet.apprikart.in`. Endpoint paths already include `/api`; do not add `/api` to the host or introduce doubled slashes.

Typed requests require HTTPS, a host, and a nonempty parent token from `AppUserDefaults.authorizationToken`. Headers are `Authorization: Bearer <parent-token>`, `Accept: application/json`, `Content-Type: application/json`, and `Accept-Language: en`. The typed request timeout is 30 seconds. Never paste a real token into code, tests, or this guide.

Successful typed calls decode `EventAPIEnvelope<Value>` and return its `data`:

```json
{"success": true, "message": "Readable server message", "data": {}}
```

`data` can be an object or array according to the route. Non-success responses normally contain `success: false` and a readable `message`. Except for the explicitly accepted create-registration `409`, a success status/envelope with missing or invalid data is not a successful operation.

### Endpoint matrix

All routes below are relative to `BASE_URL`. IDs are placeholders, not literal request values.

| Endpoint case | Method and path | Query/body | Decoded data |
| --- | --- | --- | --- |
| `EventEndpoint.list` | `GET /api/events/get-events` | `page`, `limit=10`, `sortBy=startDate`, `sortOrder=DESC`; omit `status` for All | `EventPage`: `events`, `pagination` |
| `.details` | `GET /api/events/get-event-by-id/{eventID}` | None | `EventDetails` |
| `.batches` | `GET /api/event-batches/event/{eventID}` | None | `[EventBatchSummary]` |
| `.participants` | `GET /api/events/{eventID}/participants` | `page`, `limit=20` | `EventParticipantPage`: `participants`, `pagination` |
| `.myParticipations` | `GET /api/events/parent/events/{eventID}/my-participations` | None | `[EventParticipation]` |
| `.registerFree` | `POST /api/events/parent/{eventID}/register` | Free payload below | `EventParticipation` |
| `PaymentEndpoint.registrations` | `GET /api/event-registrations/my` | `page`, `limit=50` | `EventRegistrationPage`: `registrations`, `pagination` |
| `.createRegistration` | `POST /api/event-registrations` | Paid payload below | `EventPaidRegistration` |
| `.paymentOrder` | `POST /api/event-registrations/{registrationID}/payment-order` | No body | `EventPaymentOrder` |
| `.verifyPayment` | `POST /api/event-registrations/{registrationID}/verify-payment` | Verification payload below | `EventPaidRegistration` |
| `.registration` | `GET /api/event-registrations/{registrationID}` | None | `EventPaidRegistration` |

Pagination fields are `currentPage`, `totalPages`, `totalCount`, and `limit`. Requests normalize page numbers to at least 1. The current filter values are **All, Live, Upcoming, Completed**; Completed sends `status=completed`, not `closed`.

`EndpointIdentifier.validated` rejects empty identifiers and characters outside alphanumerics, `-`, and `_`. Keep identifiers out of hand-built query strings. Use `URLQueryItem` for queries.

### Request bodies

Free registration deliberately sends consent as the **string** `"true"`:

```json
{"childId": "<selected-child-id>", "hasAgreedTerms": "true"}
```

Paid registration:

```json
{
  "childId": "<selected-child-id>",
  "eventBatchId": "<selected-batch-id>",
  "hasAgreedConsent": "true"
}
```

`grade` and `schoolName` are optional endpoint/service parameters. They are included only when nonempty. The current controller passes `nil` for both and does not display a form. The inspected `Child` model has no grade/school fields; verify the model and backend before implementing profile-based mapping. Do not invent values or collect them again merely because a sample curl contains them.

Verification uses all three SDK values, without recalculating a signature on-device:

```json
{
  "razorpayOrderId": "<order-id>",
  "razorpayPaymentId": "<payment-id>",
  "razorpaySignature": "<signature>"
}
```

### Important response fields

- `KitapiEvent`: `id`, `title`, optional `category`, `status`, optional `startDate`, `endDate`, `imageUrl`.
- `EventDetails`: flattened event fields plus description, `instructions: [{step, text}]`, prizes description, activity/fee/deadline fields, images, policy URLs, and group link. Missing instructions become `[]`.
- `EventBatchSummary`: `id`, optional name, fee/currency, start/deadline, schedule, seat availability, activity flag. `seatsAvailable == nil` is not treated as zero/full. Age eligibility is currently decided by the backend.
- `EventParticipation`: free registration's ID, child ID, status, optional child/event/group data. Recognized registered statuses are `registered`, `participant`, `participated`, `joined`, `submitted`, `winner`, `confirmed` (case-insensitive).
- `EventPaidRegistration`: ID/status plus optional child/event/batch IDs or joined objects, amount fields, confirmation date/code, and group-link locations. `ownerChildID` resolves `childId` first, then `child.id`.
- `EventPaymentOrder`: **required** `registrationId`, `razorpayOrderId`, `keyId`, `amount`, `currency`. The SDK key is supplied by this response, never hardcoded.
- Paid history must be an object containing `registrations` and `pagination`, not a bare array.

These are fields consumed by this client, not a complete backend schema. Add fixtures when the response shape changes; do not suppress decoding failures with fabricated success values.

## List and details loading

### Event list

1. The storyboard controller constructs a programmatic `UITableView` inside `mainView`.
2. `EventListViewModel.reload(filter:)` resets pagination and assigns a new generation ID.
3. `loadNextPage()` calls `EventService`, validates the returned page, deduplicates by event ID, and advances the cursor.
4. Responses from an old generation or cancelled request cannot replace the current filter's data.
5. Requests for the next page start near the last three rows. An error requires explicit retry; do not repeatedly auto-request a failing page.
6. The controller inserts appended rows instead of reloading existing cells when only pagination changes. Loading-state changes must not restart all image requests.
7. Pull-to-refresh reloads; empty, initial-loading, error, and load-more states have separate rendering.

Tapping a row uses `VCManager.openEventDetailsVC()` from `KitapiTab.storyboard`, assigns `selectedEvent`, hides the bottom tab bar, and pushes once. Do not bypass the factory or remove `EventListViewModel`.

### Event details

`EventDetailsViewModel.load(eventID:)` currently performs these calls in sequence:

1. Fetch details and publish the event.
2. Fetch batches.
3. Classify as paid when batches are nonempty **or** event fee is positive; otherwise free. Failed classification stays unknown/unsafe for registration.
4. For free events fetch my participations; for paid events fetch my paid registrations. Set `registrationChecked` only after that request succeeds.

Already-registered status is fetched even for live/completed events. Do not return early just because new registration has closed: existing users still need their registration/group information.

`EventPaymentService.registrations(eventID:)` pages through the parent's history and filters locally by `eventId` or `event.id`. It does **not** send an undocumented event filter. Empty pages stop iteration, and unexpected page numbers are errors.

Participation paging is implemented and mock-tested, but its UI tab is not exposed. About rows show description, instructions sorted by `step`, optional winner criteria, and a receipt for the selected child's confirmed paid registration.

## Free registration

```text
Selected child + event ID + accepted consent
  -> ViewModel.register(...)
  -> EventDetailsService.registerFree(...)
  -> EventEndpoint.registerFree
  -> APIClient -> POST /api/events/parent/{eventID}/register
  -> save free participation -> update footer
```

The ViewModel blocks missing child, child mode, missing consent, duplicate registration, loading/in-flight registration, wrong event ID, unknown/paid classification, unchecked registration state, and a closed event.

If registration throws, it fetches my participations once before offering another attempt: a timeout/duplicate response may follow a successful backend commit. If the child is now registered, do not show a false failure. Free registration never creates a paid registration or opens Razorpay.

## Paid registration and checkout

```text
Consent + selected child + eligible batch
  -> POST create/resume registration
     -> already confirmed? Store it; no checkout
     -> unfinished? POST payment-order
  -> validate server order + convert rupees to paise
  -> open Razorpay directly
     -> cancelled/failed: keep unconfirmed, allow retry
     -> SDK success: POST verify-payment with all three proof fields
  -> backend confirmed? Success card + receipt + eligible group access
     -> uncertain/failure: GET registration to reconcile server state
```

### Selection and initiation

- `chooseBatch()` filters batches with `acceptsRegistration(at:)`. No eligible batch produces a SwiftMessages error.
- One eligible batch is selected automatically. Multiple eligible batches use a selection sheet, not a grade/school form.
- `prepareRegistration` rechecks the selected child and calls `preparePayment` with the event and batch IDs.
- `preparePayment` sets `isRegistering`; validates matching child/event/batch information when present; stores the returned record; and requests an order for that exact registration.
- The order must match the registration ID and have nonempty order/key IDs and a supported amount.
- `startCheckout` rechecks visible screen, selected child, parent mode, event and batch availability. It dismisses an outstanding selection sheet before opening the SDK.
- There is **no** extra review/Pay Now alert. Razorpay itself presents the payable amount and payment authorization UI.
- A backend rejection such as age ineligibility must not continue to order creation or checkout.

### Amount and SDK contract

`EventMoney` uses `Decimal`, not floating-point arithmetic. Current checkout accepts only **positive INR amounts** that convert to an exact integer number of paise within `Int` range. Example: backend `"999.25"` becomes SDK `99925`. Negative, zero, fractional-paise, overflowing, malformed, and unsupported-currency amounts fail validation. Currency display currently assumes INR.

`EventCheckout` uses the already-installed Razorpay package and `RazorpayPaymentCompletionProtocolWithData`. It retains the SDK instance, prevents concurrent checkout, verifies the callback's order ID, requires nonempty payment ID/signature, and delivers the completion only once. Do not switch to the payment-ID-only delegate.

SDK options use the **latest server order**: `order_id`, converted `amount`, `currency`, and `keyId` for initialization. Do not trust an event-card fee as the final amount or put a Razorpay secret in the app.

### Confirmation, conflicts, and retries

- Paid statuses expected by the flow are `draft`, `payment_pending`, and terminal `confirmed`. Only the last counts as registered.
- `PaymentEndpoint.createRegistration` alone opts into decoding an HTTP `409` body. A conflict can contain an existing confirmed registration even with `success: false`. Preserve `data`; still validate the record and its status. Never treat all `409` responses as success.
- A payment-order error triggers a registration-detail read when a matching stored record is available; the webhook might already have confirmed it.
- Verification checks the active order ID and all proof fields. A successful response must identify the expected registration/child and have `status == confirmed`.
- Verification failure/timeout triggers a detail read for reconciliation. Success may come from this server read after a webhook, not from the SDK callback alone.
- Unresolved valid proof is kept **in memory**. `Retry Payment Verification` resends that proof instead of creating another payment/order.
- If child mode becomes active before verification, keep the proof for retry after exiting child mode; do not send protected writes in child mode.
- `finishCheckout` clears active order/checkout-child state and resets the busy flag. Cancellation does not mark the registration confirmed.
- The current Continue Payment path calls create/resume again and then requests an order. Safe reuse of registration/order and charging behavior is a backend contract to verify in integration testing, not a client-generated guarantee.

## Registration availability and footer

Current client rules are deliberately conservative:

- Event must be active, have status `upcoming`, and have a parseable future start date.
- If an event deadline is supplied, it must parse and not have elapsed.
- Batch must not be explicitly inactive or have zero available seats. Its supplied start/deadline must parse and be in the allowed range.
- Date-only deadlines include the full **UTC** calendar day; ISO timestamps are compared as instants. A start date still closes registration at that start instant. Backend decisions remain authoritative.
- The visible controller reevaluates availability every second while appearing and cancels that task on disappearance.

| Selected-child state | Footer behavior |
| --- | --- |
| Open, free, not registered | Participate; enabled only with consent, selected child, parent mode, and completed registration check |
| Open, paid, not registered | Pay amount / Select Batch & Pay, or Continue Payment for unfinished history |
| Request/checkout in progress | Registering / Processing payment; action and back button disabled |
| Valid proof awaiting verification | Retry Payment Verification; consent row hidden |
| Registered with valid group link | Green Join WhatsApp Group button; consent hidden |
| Registered without valid group link | Registered indicator/button, disabled; no fabricated group link |
| Closed, not registered, no pending proof | Entire booking footer collapses to zero height |
| Closed but registered or pending verification | Keep registration/group access or verification retry visible |

Do not hide an existing registration's access just because new registrations have stopped. Changing children clears consent and rerenders against the new child's registration state.

## Identity, persistence, and WhatsApp

The live event-screen source of truth is `ChildManager.shared.selectedChild`, not a cached sample ID or a batch object. `ChildSessionManager` separately persists/restores a selected child under the UserDefaults key `selectedChild`. Do not assume those managers synchronize automatically: inspect the selection/restore call sites before changing identity behavior. The parent token comes from `AppUserDefaults.authorizationToken`.

Paid `groupURL` requires confirmed status and prefers `batch.whatsappGroupLink`, then `event.whatsappGroupLink`, then the registration's top-level link. Free access requires a recognized participation for that child and prefers its direct link, then joined event link, then details' event link.

`EventGroupLink` accepts only `https://chat.whatsapp.com/<nonempty-path>` without URL credentials. A bad/missing preferred link is not replaced with an invented URL. The controller uses `UIApplication.shared.open`, outside the app's embedded policy browser; iOS may open WhatsApp or the configured browser. It does not force Safari. Child mode blocks the action.

There is no on-disk payment-proof cache. After relaunch the app reloads server registration history; it cannot resend a lost in-memory signature. Never persist signatures in UserDefaults or add recovery storage without an explicit design/security decision.

## UI rules and past regressions

- List uses a `UITableView`; details use a `UITableView` with a horizontally paging `UICollectionView` hero gallery and a separate pinned footer.
- Reuse `EventFilterTab` for details tabs. `visibleTabs` currently contains only `.about`; Participation remains hidden even though its data plumbing exists.
- Use `Fonts` from `KitapiFonts.swift` and colors from `ColorPalette.swift`; do not scatter replacement fonts/hex values through controllers.
- Content outer margins are normally 16 points. Category text has 12-point horizontal and 6-point vertical insets; the details pill has a text-measured preferred width capped at 45% of the metadata row. Long text wraps rather than stretching a short label's pill across the row.
- The main details title wraps and reserves at least two lines of height. Compact navigation title supports two lines in the 56-point navigation overlay.
- `updateCollapsingHeader` keeps the compact title hidden until valid geometry exists and the image/full title have passed behind the opaque header. Recalculate after layout and scrolling. Never derive an initially visible title from zero-size frames.
- `updateHeaderHeight` lays out the header and preserves table scroll offset while reassigning `tableHeaderView`. Keep this protection when changing metadata/title constraints.
- Details status is anchored **16 points from the hero's bottom and right**, not at its top. List cards retain their own corner-ribbon style.
- Honor Reduce Motion for parallax/transitions. Do not add a competing fixed title over the image.
- List and hero images use Kingfisher activity indicators, downsampling, caching, background decode, fallbacks, and reuse cancellation. Do not replace them with synchronous downloads or reload all list images on each loading-state change.
- Details accepts a primary image plus `images` or `imageUrls`, with object/string/array image representations and URL deduplication. A single/no image hides pagination dots. Gallery pages use full container width.
- `EventDateText` parses `dd-MM-yyyy` and ISO timestamps and displays English ordinal dates, e.g. `23rd Oct – 29th Oct – 2026`, `30th Oct – 2nd Nov – 2026`, or `30th Dec 2026 – 2nd Jan 2027`. Preserve 11th/12th/13th handling and missing-date fallbacks.

Legal links are built from `APPConstants.eventTermsURL`, `eventPrivacyURL`, and `eventMediaPolicyURL` and opened through `SFSafariViewController` after HTTPS validation:

- `https://kitapi.apprikart.in/termsAndConditions`
- `https://kitapi.apprikart.in/privacyPolicy`
- `https://kitapi.apprikart.in/mediaPolicy`

The model decodes API policy URL fields, but the current consent-link builder uses these constants; do not claim server-driven policy links are already wired.

## Errors, authentication, and logs

### Presentation

`errorMessage` is a details-load failure; `bookingError` is a batch/history/classification read failure. These support in-screen retry states. `registrationError` is a transient free-registration/payment failure.

After a write/checkout failure, the controller calls `showRegistrationFailureIfNeeded()`, consumes the message through `consumeRegistrationError()`, and uses its injectable `errorPresenter`. Production presentation is `MessageManager.shared.show(message: ..., type: .error)` from the existing SwiftMessages wrapper. Consumption prevents repeated renders from showing duplicate alerts. Offscreen controllers do not present the banner.

Show a server message such as `Child's age is not eligible for this batch`; do not display the surrounding JSON, stack trace, token, or a persistent footer copy. No order/checkout should follow that rejection.

### Shared client compatibility

`APIClient` now has one HTTP execution/decoding helper, `performJSONRequest`. Existing static JSON and multipart calls retain their `APIResponse<T>` contracts. Typed endpoint calls unwrap `EventAPIEnvelope<Value>` and throw errors for ViewModel handling.

- `401`: existing authentication-failure handler, then typed sign-in error.
- `EventListViewModel` and `EventDetailsViewModel` handle `.signInRequired` separately, set `requiresSignIn`, and stop loading without an inline error or SwiftMessages banner. The centralized `SessionManager` owns the session-expired UI; ViewModels must not post a second alert or initiate logout themselves.
- Once sign-in is required, automatic pagination, participant paging, protected actions, and post-failure reconciliation stop. The details booking footer is hidden and group access is blocked. A late checkout callback cannot produce another error banner. An explicit reload resets the flag; otherwise the login/root flow supplies fresh screen state.
- If authentication expires during a recovery/detail read, suppress the original registration/payment error too. Do not hide authentication errors inside `try?` recovery calls or create another payment attempt. Session-bound pending proof is cleared on authentication failure rather than reused for a new login.
- Typed event/payment `403`: readable domain error; **not** automatic logout, because child mode/permissions may forbid an operation.
- Legacy static JSON/multipart `403`: existing authentication-failure behavior is retained. Do not silently change this app-wide policy while editing events.
- Typed decoding failures preserve `DecodingError` diagnostics; legacy decoding failures remain `.decodingFailed`.
- Cancellation is preserved; missing parent tokens fail before sending typed requests.

### Diagnostics

Filter Xcode logs by `[EventAPI]` and correlate the request ID:

```text
[EventAPI][<request-id>] POST /api/event-registrations REQUEST
[EventAPI][<request-id>] POST /api/event-registrations RESPONSE status=400 bytes=...
[EventAPI][<request-id>] POST /api/event-registrations RESPONSE BODY
{"success":false,"message":"Child's age is not eligible for this batch"}
[EventAPI][<request-id>] POST /api/event-registrations FAILED status=400 durationMs=... reason=...
```

List logs also include filter/page and successful pagination counts. Legacy shared-client calls use `[API]`. Default logging and response-body dumps are DEBUG-only. JSON redaction covers token/password/secret keys, authorization, and Razorpay signatures; headers and binary multipart bodies are not dumped. Response payloads can still contain personal data: sanitize before sharing and never enable unrestricted production logging. Non-JSON body fallback is not a universal secret scrubber.

## Making changes safely

### Find the correct layer

| Requested change | Start here | Must preserve/check |
| --- | --- | --- |
| Add/change route, query, or JSON payload | `EventEndpoint` / `PaymentEndpoint`, then service/model | Endpoint tests, string consent, identifier validation |
| Change auth, timeout, transport, or response policy | Existing `APIClient` in `NetworkService.swift` | Legacy JSON/multipart tests; typed 403 vs 401; accepted 409 data |
| Fix list filtering/pagination | `EventListFilter`, `EventListViewModel`, `EventService` | Completed status, generation guard, deduplication, stable cells |
| Change details layout/header/gallery | Controller, constraints, card/hero cells | Initial/return-to-top title hidden, two-line title space, compact category, bottom-right badge |
| Change registration eligibility | Details/batch model methods and ViewModel guards | Fake-clock date tests; backend remains authoritative |
| Change checkout/provider behavior | `EventCheckout` behind `EventCheckoutPresenting` | Exact paise conversion, all proof fields, no SDK-only confirmation |
| Change retry/recovery | `EventDetailsViewModel` | No second charge for verification retry, generation/child/order checks |
| Change error UX | Controller error presenter + transient error consumption | One banner; no raw JSON; no inline registration error |
| Show Participation | `visibleTabs`, selection/loading/rendering, participant service/model | Requires product approval; empty/error/paging design and tests |
| Add profile-derived optional registration data | Child model/selection source, then `prepareRegistration` mapping | Verify actual fields; no unnecessary popup or invented values |

### Developer/AI checklist

1. Read applicable repository/user instructions, this guide, the relevant source, and its tests before editing. Inspect the working tree and preserve unrelated user changes.
2. Confirm whether the request is explanation, diagnosis, review, or implementation; do not turn a question into an unrequested rewrite.
3. Keep `EventListViewModel`, `EventDetailsViewModel`, `VCManager`, and the single existing `APIClient`. Avoid parallel architectures or new networking dependencies.
4. Keep state/eligibility logic out of cells. Keep raw paths/bodies out of controllers. Change one layer at a time and update dependent models/tests together.
5. Keep ViewModel mutations on `@MainActor`; preserve busy flags, generation IDs, cancellation checks, and callback deduplication. Never allow an old response to overwrite a new filter/event/child state.
6. Never confirm payment, reveal a paid group link, or show paid success from local state or an SDK callback alone. Preserve server ownership/order validation.
7. Add/update XCTest fixtures and `URLProtocol` mocks. Inject service protocols, `APIClientProtocol`, `EventCheckoutPresenting`, and `errorPresenter` instead of contacting live systems.
8. Inspect initial/scrolled/resized screenshots after UI work. Verify missing images, long titles/categories, wrapped dates, footer visibility, and child changes, not just the happy path.
9. Update this document for contract/flow changes. Report exactly which tests ran and any remaining device/backend checks; do not claim production readiness from mocks alone.

## Tests and release checks

| Suite | Coverage to consult |
| --- | --- |
| [EndpointTests.swift](../KitapiTests/EndpointTests.swift) | All endpoint paths/methods, consent/optional fields, query/filter mapping, identifiers, headers |
| [NetworkServiceTests.swift](../KitapiTests/NetworkServiceTests.swift) | Legacy JSON/multipart compatibility, shared transport, typed vs legacy auth policy, decoding contracts |
| [EventListTests.swift](../KitapiTests/EventListTests.swift) | Filters, dates/images, stale responses, pagination/retry, network/logging mocks, stable cards, navigation/layout |
| [EventDetailsTests.swift](../KitapiTests/EventDetailsTests.swift) | Details decoding, registration cutoffs/consent/child mode, participants, free API, links, category/title/status layout |
| [EventPaymentTests.swift](../KitapiTests/EventPaymentTests.swift) | Exact money, server confirmation, cancel/retry, webhook reconciliation, wrong order, existing registration, direct checkout, age-error banner, group access |
| [EventAuthenticationTests.swift](../KitapiTests/EventAuthenticationTests.swift) | Sign-in failure at list/details/history/participant/register/order/verify stages, no duplicate local errors or auth retries, reconciliation auth failures, permission errors still visible |

Last full code verification: **63 tests passed on 15 October 2026**, including authentication handling across event loading, registration, and payment. Rerun tests after subsequent changes.

From the repository root, inspect available destinations, then replace the UDID placeholder:

```sh
xcrun simctl list devices available
xcodebuild -project Kitapi.xcodeproj -scheme Kitapi -showdestinations

xcodebuild -quiet \
  -project Kitapi.xcodeproj \
  -scheme Kitapi \
  -destination 'platform=iOS Simulator,id=REPLACE_WITH_SIMULATOR_UDID' \
  -derivedDataPath /tmp/kitapi-event-tests \
  CODE_SIGNING_ALLOWED=NO \
  test
```

For a targeted run, add e.g. `-only-testing:KitapiTests/EndpointTests` or `-only-testing:KitapiTests/EventPaymentTests`. Run the complete suite after shared-client changes. Xcode/simulator caches may require normal host permissions; a sandbox permission failure is not a Swift compile failure.

Before a payment release, explicitly authorize and perform a **Razorpay test-mode** device/backend integration pass: free registration, paid success, cancellation, failure, verification timeout/retry, existing confirmed registration, webhook-delayed confirmation, process restart, child-mode rejection, age/full/closed batch errors, and absent/invalid/valid group links. Confirm server keys/webhook configuration with the backend owner. Do not use real money for routine verification.

The app already includes Razorpay through SPM; inspect `Package.resolved`/project configuration before upgrades. `Info.plist` declares UPI query schemes `tez`, `phonepe`, `paytmmp`. Simulator tests do not prove real-device UPI hand-off or payment-provider availability.

## Known limitations and troubleshooting

These are current boundaries, not automatically approved work:

- Participation is hidden; registration/submission/winner screens beyond the documented UI are not enabled by this implementation.
- There is no refund/cancellation API in the current client. Do not suggest a refund flow exists.
- There is no persistent pending-proof queue or background verification polling. Resume/reconciliation relies on explicit retry and server history/detail reads; losing in-memory proof needs server-side confirmation/recovery planning.
- Paid history is scanned across pages per details load and filtered locally. Large histories may need a documented server filter/cache later; do not silently invent query support.
- Only INR checkout/display is supported. Batch age limits are not modeled for client-side eligibility filtering; backend errors are presented to the parent.
- UTC date-only cutoffs are the implemented assumption. Any switch to local/event time zones must be agreed with the backend and covered by boundary tests.
- Selected-child persistence and the event screen's runtime selection live in separate managers. Verify restoration/synchronization before relying on stored selection.
- Endpoint definitions and services have unit coverage; backend response changes still require representative fixtures and integration verification.

| Symptom | Check first |
| --- | --- |
| Age eligibility `400` | Backend batch/child rules; expect one SwiftMessages error and no order/SDK call |
| Paid action disabled/unavailable | Classification/history failure, `registrationChecked`, selected child, consent, child mode, busy state, deadline/start |
| Registered but no WhatsApp action | Selected-child ownership, confirmed/recognized status, configured link location, exact allowed HTTPS host/path |
| No group access after event starts | Confirm loading was not short-circuited on closed availability and footer retained registered state |
| Payment success callback but not registered | Verify API result/detail read, signature/order values, captured/backend status; never force local success |
| Repeat verification asks to pay again | `pendingVerification`, selected child/order ownership, retry path versus new checkout path |
| `409` looks like a generic failure | Only create-registration accepts it; check preserved `data`, record status, registration/child/event/batch IDs |
| Unexpected logout on payment `403` | Typed API must pass `forbiddenMeansAuthenticationFailure: false`; verify shared-client tests |
| Event list data changes after switching tabs | Generation guard, cancellation, current filter, page response number |
| Missing/incorrect dates | API format, UTC/ISO parsing, ordinal formatter and month/year boundary tests |
| Compact title appears over image | Zero/stale geometry, post-layout update, reveal threshold, opaque background, scroll-offset preservation |
| Category stretches or clips | Text measurement, 999-priority preferred width, required max width, hugging priorities, wrapping; do not measure width from unstable intrinsic size alone |
| Decode error | `[EventAPI]` request ID, status/body, `missingKey`/type-mismatch path; update the correct model/fixture rather than swallowing the error |

Additional backend reference files may exist in the workspace's sibling `../Docs` directory: `16-event-payments.pdf`, `RAZORPAY_FRONTEND_INTEGRATION_GUIDE.pdf`, and `KITA.postman_collection(06-10-2026).json`. They are outside this repository's `Docs` directory and may not accompany a clone. Review their current contents with the backend owner when changing contracts; do not treat older sample credentials or payloads as production configuration.
