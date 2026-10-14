import UIKit
import Razorpay

@MainActor protocol EventCheckoutPresenting: AnyObject {
    func open(order: EventPaymentOrder, controller: UIViewController, completion: @escaping (Result<EventPaymentProof, any Error>) -> Void) throws
}

@MainActor final class EventCheckout: NSObject, EventCheckoutPresenting, RazorpayPaymentCompletionProtocolWithData {
    private var razorpay: RazorpayCheckout?
    private var completion: ((Result<EventPaymentProof, any Error>) -> Void)?
    private var expectedOrderID: String?
    nonisolated deinit {}

    func open(order: EventPaymentOrder, controller: UIViewController, completion: @escaping (Result<EventPaymentProof, any Error>) -> Void) throws {
        guard self.completion == nil else { throw EventServiceError.server("A payment is already in progress.") }
        let amount = try order.amount.paise(currency: order.currency)
        self.completion = completion
        expectedOrderID = order.razorpayOrderId
        razorpay = RazorpayCheckout.initWithKey(order.keyId, andDelegateWithData: self)
        razorpay?.open(["order_id": order.razorpayOrderId, "amount": amount, "currency": order.currency,
                        "name": "Kitapi", "description": controller.title ?? "Event registration"], displayController: controller)
    }

    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable: Any]?) {
        guard let order = response?["razorpay_order_id"] as? String, order == expectedOrderID,
              let signature = response?["razorpay_signature"] as? String, !signature.isEmpty, !payment_id.isEmpty else {
            finish(.failure(EventServiceError.server("Incomplete payment response. Please refresh your registration status."))); return
        }
        finish(.success(EventPaymentProof(razorpayOrderId: order, razorpayPaymentId: payment_id, razorpaySignature: signature)))
    }

    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable: Any]?) {
        finish(.failure(EventServiceError.server(code == 2 ? "Payment cancelled. Your registration is not confirmed yet. Continue payment when ready." : "Payment could not be completed. Please try again.")))
    }

    private func finish(_ result: Result<EventPaymentProof, any Error>) {
        let callback = completion
        completion = nil
        expectedOrderID = nil
        callback?(result)
    }
}
