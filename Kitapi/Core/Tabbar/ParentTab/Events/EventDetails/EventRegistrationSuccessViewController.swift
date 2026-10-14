import UIKit

final class EventRegistrationSuccessViewController: UIViewController {
    var amount: String?
    var joinGroup: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        let preferredWidth = card.widthAnchor.constraint(equalToConstant: 430)
        preferredWidth.priority = .defaultHigh
        preferredWidth.isActive = true
        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = .greenPrimaryColor
        check.contentMode = .scaleAspectFit
        check.heightAnchor.constraint(equalToConstant: 36).isActive = true
        let title = label("Registration Successful!", font: Fonts.urbanistBold, size: 20, color: .greenPrimaryColor)
        let amountLabel = label(amount ?? "Confirmed", font: Fonts.urbanistBold, size: 24, color: .textColor)
        let subtitle = label("Your registration is confirmed.", font: Fonts.urbanistRegular, size: 14, color: .labelPlaceholderColor)
        let join = UIButton(type: .system)
        join.setTitle("Join WhatsApp Group", for: .normal)
        join.setTitleColor(.white, for: .normal)
        join.titleLabel?.font = UIFont(name: Fonts.urbanistBold, size: 16)
        join.backgroundColor = .greenPrimaryColor
        join.layer.cornerRadius = 24
        join.heightAnchor.constraint(equalToConstant: 48).isActive = true
        join.isHidden = joinGroup == nil
        join.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let action = self.joinGroup
            self.dismiss(animated: true) { action?() }
        }, for: .touchUpInside)
        let close = UIButton(type: .system)
        close.setTitle("Done", for: .normal)
        close.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        close.tintColor = .textColor
        close.heightAnchor.constraint(equalToConstant: 44).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [check, title, amountLabel, subtitle, join, close])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor), blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.topAnchor.constraint(equalTo: view.topAnchor), blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor), card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9), card.widthAnchor.constraint(lessThanOrEqualToConstant: 430),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24), stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        UIAccessibility.post(notification: .screenChanged, argument: title)
    }

    private func label(_ text: String, font: String, size: CGFloat, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: font, size: size)
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }
}
