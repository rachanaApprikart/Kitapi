import UIKit

final class EventDetailsCardCell: UITableViewCell {
    static let reuseIdentifier = "EventDetailsCardCell"
    private let headingLabel = UILabel()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        headingLabel.font = UIFont(name: Fonts.urbanistBold, size: 20) ?? .boldSystemFont(ofSize: 20)
        titleLabel.font = UIFont(name: Fonts.urbanistBold, size: 18) ?? .boldSystemFont(ofSize: 18)
        bodyLabel.font = UIFont(name: Fonts.urbanistRegular, size: 16) ?? .systemFont(ofSize: 16)
        for label in [headingLabel, titleLabel, bodyLabel] { label.numberOfLines = 0; label.textColor = .textColor }
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.buttonBorderColor.cgColor
        let inner = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        inner.axis = .vertical
        inner.spacing = 10
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        let stack = UIStackView(arrangedSubviews: [headingLabel, card])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { return nil }

    func configure(heading: String?, title: String?, body: String) {
        headingLabel.text = heading
        headingLabel.isHidden = heading == nil
        titleLabel.text = title
        titleLabel.isHidden = title == nil
        bodyLabel.text = body
    }
}
