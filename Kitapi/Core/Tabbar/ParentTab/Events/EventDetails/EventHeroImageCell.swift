import UIKit
import Kingfisher

final class EventHeroImageCell: UICollectionViewCell {
    static let reuseIdentifier = "EventHeroImageCell"
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .pinkPrimaryColor
        imageView.kf.indicatorType = .activity
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor), imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { return nil }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
    }

    func configure(url: URL?) {
        imageView.kf.cancelDownloadTask()
        guard let url else { imageView.image = UIImage(systemName: "photo"); return }
        imageView.kf.setImage(with: url, options: [.processor(DownsamplingImageProcessor(size: CGSize(width: 600, height: 360))), .scaleFactor(traitCollection.displayScale), .cacheOriginalImage, .backgroundDecode, .onFailureImage(UIImage(systemName: "photo"))])
    }
}
