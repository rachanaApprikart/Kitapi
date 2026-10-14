import UIKit
import Kingfisher

final class EventCardCell: UITableViewCell {
    static let reuseIdentifier = "EventCardCell"
    private let card = UIView()
    private let artwork = UIImageView()
    private let statusLabel = EventStatusRibbon()
    private let categoryLabel = UILabel()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }

    required init?(coder: NSCoder) { super.init(coder: coder); buildUI() }

    override func prepareForReuse() {
        super.prepareForReuse()
        artwork.kf.cancelDownloadTask()
        artwork.kf.indicator?.stopAnimatingView()
        artwork.image = nil
        accessibilityLabel = nil
    }

    func configure(with event: KitapiEvent) {
        artwork.kf.cancelDownloadTask()
        artwork.kf.indicator?.stopAnimatingView()
        titleLabel.text = event.title
        categoryLabel.text = event.category?.isEmpty == false ? event.category : "Event"
        categoryLabel.superview?.backgroundColor = EventCardStyle.categoryTint(event.category)
        dateLabel.text = EventDateText.range(start: event.startDate, end: event.endDate)
        statusLabel.text = "  \(event.displayStatus)  "
        switch event.status.lowercased() {
        case "live": statusLabel.backgroundColor = .greenPrimaryColor
        case "upcoming": statusLabel.backgroundColor = .orangePrimaryColor
        default: statusLabel.backgroundColor = .buttonBackgroundColor
        }
        let placeholder = UIImage(systemName: "calendar")
        artwork.image = placeholder
        if let value = event.imageUrl?.url, let url = URL(string: value),
           ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
            let width = max(160, contentView.bounds.width * 0.38)
            let processor = DownsamplingImageProcessor(size: CGSize(width: width, height: width * 0.8))
            artwork.kf.setImage(with: url, placeholder: nil, options: [
                .processor(processor),
                .scaleFactor(traitCollection.displayScale),
                .cacheOriginalImage,
                .backgroundDecode,
                .onFailureImage(placeholder),
                .transition(.fade(0.15))
            ])
        }
        accessibilityLabel = [event.displayStatus, event.category, event.title, dateLabel.text].compactMap { $0 }.joined(separator: ", ")
    }

    private func buildUI() {
        backgroundColor = .clear
        selectionStyle = .none
        isAccessibilityElement = true
        accessibilityTraits = .button
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.buttonBorderColor.cgColor
        artwork.contentMode = .scaleAspectFit
        artwork.clipsToBounds = true
        artwork.layer.cornerRadius = 12
        artwork.backgroundColor = .gradientColor3
        artwork.tintColor = .pinkPrimaryColor
        artwork.kf.indicatorType = .activity
        statusLabel.textColor = .white
        statusLabel.font = UIFont(name: Fonts.urbanistMedium, size: 13) ?? .systemFont(ofSize: 13)
        statusLabel.clipsToBounds = true
        categoryLabel.font = UIFont(name: Fonts.urbanistBold, size: 12) ?? .boldSystemFont(ofSize: 12)
        categoryLabel.textColor = .textColor
        categoryLabel.textAlignment = .center
        categoryLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: Fonts.urbanistBold, size: 16) ?? .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .textColor
        titleLabel.numberOfLines = 0
        dateLabel.font = UIFont(name: Fonts.urbanistMedium, size: 13) ?? .systemFont(ofSize: 13)
        dateLabel.textColor = .textColor
        dateLabel.numberOfLines = 0
        let calendar = UIImageView(image: UIImage(systemName: "calendar"))
        calendar.tintColor = .textColor
        calendar.contentMode = .scaleAspectFit
        let dates = UIStackView(arrangedSubviews: [calendar, dateLabel])
        dates.spacing = 5
        dates.alignment = .top
        calendar.widthAnchor.constraint(equalToConstant: 14).isActive = true
        calendar.heightAnchor.constraint(equalToConstant: 14).isActive = true
        let categoryPill = UIView()
        categoryPill.layer.cornerRadius = 13
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryPill.addSubview(categoryLabel)
        NSLayoutConstraint.activate([
            categoryLabel.leadingAnchor.constraint(equalTo: categoryPill.leadingAnchor, constant: 12),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryPill.trailingAnchor, constant: -12),
            categoryLabel.topAnchor.constraint(equalTo: categoryPill.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryPill.bottomAnchor, constant: -4)
        ])
        let categoryRow = UIStackView(arrangedSubviews: [categoryPill, UIView()])
        let text = UIStackView(arrangedSubviews: [categoryRow, titleLabel, dates])
        text.axis = .vertical
        text.spacing = 7
        categoryPill.heightAnchor.constraint(greaterThanOrEqualToConstant: 26).isActive = true
        for (subview, parent) in [(card, contentView), (artwork, card), (text, card), (statusLabel, card)] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            artwork.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            artwork.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            artwork.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.34),
            artwork.heightAnchor.constraint(equalTo: artwork.widthAnchor, multiplier: 0.8),
            artwork.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14),
            text.leadingAnchor.constraint(equalTo: artwork.trailingAnchor, constant: 12),
            text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            text.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            text.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            statusLabel.topAnchor.constraint(equalTo: card.topAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
}
