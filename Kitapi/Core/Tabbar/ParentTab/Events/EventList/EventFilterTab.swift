import UIKit

/// The raised selected tab joins the cream surface below the filter row.
class EventFilterTab: UIView {
    let button = UIButton(type: .system)
    private let title: String
    private let tabMask = CAShapeLayer()

    init(title: String, action: @escaping () -> Void) {
        self.title = title
        super.init(frame: .zero)
        clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 36)
        ])
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        setSelected(false)
    }

    required init?(coder: NSCoder) { return nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        tabMask.frame = bounds
        tabMask.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 16, height: 16)).cgPath
        layer.mask = tabMask
    }

    override var intrinsicContentSize: CGSize {
        let font = UIFont(name: Fonts.urbanistBold, size: 15) ?? .boldSystemFont(ofSize: 15)
        return CGSize(width: (title as NSString).size(withAttributes: [.font: font]).width + 40, height: 60)
    }

    func setSelected(_ selected: Bool) {
        backgroundColor = selected ? .gradientColor1 : .clear
        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont(name: Fonts.urbanistBold, size: 15) ?? .boldSystemFont(ofSize: 15)
        ]))
        configuration.baseForegroundColor = selected ? .white : .buttonTitleColor
        configuration.baseBackgroundColor = selected ? .buttonBackgroundColor : .gradientColor1
        configuration.background.cornerRadius = 12
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        button.configuration = configuration
        button.accessibilityTraits = selected ? [.button, .selected] : [.button]
    }
}

