//
//  VideoPlayerCVCell.swift
//  Kitapi
//
//  Created by Suneel on 23/12/25.
//

import UIKit
import AVFoundation

class VideoPlayerCVCell: UICollectionViewCell {
    
    @IBOutlet weak var videoPlayerView: UIView!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    
    static var reUseIdentifier: String {
        return String(describing: VideoPlayerCVCell.self)
    }
    
    static var nibFile: UINib {
        return UINib(nibName: VideoPlayerCVCell.reUseIdentifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }
    
    func configure(with player: AVPlayer?) {
        // Remove old player layer
        playerLayer?.removeFromSuperlayer()

        self.player = player
        guard let player = player else { return }
        
        // Create new player layer
        let layer = AVPlayerLayer(player: player)
        layer.frame = videoPlayerView.bounds
        layer.videoGravity = .resizeAspectFill
        videoPlayerView.layer.addSublayer(layer)
        
        playerLayer = layer
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }
}
