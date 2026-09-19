//
//  OnboardingViewController.swift
//  Kitapi
//
//  Created by Suneel on 22/12/25.
// Modified on 30-3-2026

import UIKit
import AVFoundation

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var appBGView: UIView!
    
    @IBOutlet weak var onboardingCV: UICollectionView!
    @IBOutlet weak var video1to2: UIButton!
    
    @IBOutlet weak var buttonsView: UIStackView!
    @IBOutlet weak var nextVideoBtn: UIButton!
    @IBOutlet weak var previousVideoBtn: UIButton!
    @IBOutlet weak var videoPageControl: UIPageControl!
    
    
    private var players: [Int: AVPlayer] = [:]
    private var currentPage: Int = 0
    
    private let videoNames = ["1", "2", "3", "4"]
    
    static var sbIdentifier: String {
        return String(describing: OnboardingViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setOnboardingScreenUI()
        self.addVideoObservers()
        AppUserDefaults.IS_ON_BOARDING_SCREEN_VIEWED = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.playVideo(at: 0)
        self.updateButtonStates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAllVideos()
    }
    
    @IBAction func video1to2BtnAction(_ sender: UIButton) {
        guard currentPage < videoNames.count - 1 else { return }
        let nextPage = currentPage + 1
        let indexPath = IndexPath(item: nextPage, section: 0)
        self.onboardingCV.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.playVideo(at: nextPage)
        self.updateButtonStates()
    }
    
    //31-3-2026
    
    @IBAction func previousVideoAction(_ sender: UIButton) {
        guard currentPage > 0 else { return }
        let previousPage = currentPage - 1
        let indexPath = IndexPath(item: previousPage, section: 0)
        self.onboardingCV.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.videoPageControl.currentPage = previousPage
        self.playVideo(at: previousPage)
        self.updateButtonStates()
    }
    
    @IBAction func nextVideoAction(_ sender: UIButton) {
        guard currentPage < videoNames.count - 1 else {
            self.stopAllVideos()
            self.navigateToLoginVC()
            return }
        
        let nextPage = currentPage + 1
        let indexPath = IndexPath(item: nextPage, section: 0)
        self.onboardingCV.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.videoPageControl.currentPage = nextPage
        self.playVideo(at: nextPage)
        self.updateButtonStates()
    }
    
    private func playVideo(at index: Int) {
        guard index >= 0 && index < videoNames.count else { return }
        
        // Pause all videos
        players.values.forEach { $0.pause() }
        
        // Get or create player for this index
        if players[index] == nil {
            guard let videoURL = Bundle.main.url(forResource: videoNames[index], withExtension: "mp4") else {
                return
            }
            players[index] = AVPlayer(url: videoURL)
        }
        // Play selected video
        if let player = players[index] {
            player.seek(to: .zero)
            player.play()
        }
        currentPage = index
    }
    
    private func addVideoObservers() {
        // Loop videos when they finish
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    @objc private func videoDidFinish(notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        
        // Find which player finished
        for (index, player) in players {
            if player.currentItem == playerItem {
                // Calculate next video index
                let nextIndex = index + 1
                
                // Check if there's a next video
                if nextIndex < videoNames.count {
                    // Scroll to next video
                    let nextIndexPath = IndexPath(item: nextIndex, section: 0)
                    self.onboardingCV.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
                    self.videoPageControl.currentPage = nextIndex
                    self.playVideo(at: nextIndex)
                    self.updateButtonStates()
                } else {
                    // Last video finished -
//                    let firstIndexPath = IndexPath(item: 0, section: 0)
//                    self.onboardingCV.scrollToItem(at: firstIndexPath, at: .centeredHorizontally, animated: true)
//                    self.videoPageControl.currentPage = 0
//                    self.playVideo(at: 0)
//                    self.updateButtonStates()
                    break
                }
            }
        }
    }
    
    private func stopAllVideos() {
        self.players.values.forEach { player in
            player.pause()
            player.seek(to: .zero)
        }
        self.players.removeAll()
    }
    
    fileprivate func navigateToLoginVC() {
        guard let vc = VCManager.openLoginVC() else { return  }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.players.values.forEach { $0.pause() }
    }
}

//MARK: COLLECTION VIEW DELEGATES

extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let onBoardCVCell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoPlayerCVCell.reUseIdentifier, for: indexPath) as? VideoPlayerCVCell else {
            return UICollectionViewCell() }
        
        // Get or create player
        if players[indexPath.item] == nil {
            if let videoURL = Bundle.main.url(forResource: videoNames[indexPath.item], withExtension: "mp4") {
                players[indexPath.item] = AVPlayer(url: videoURL)
            }
        }
        onBoardCVCell.configure(with: players[indexPath.item])
        return onBoardCVCell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.onboardingCV.frame.width, height: self.onboardingCV.frame.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        self.videoPageControl.currentPage = page
        self.playVideo(at: page)
        self.updateButtonStates()
     }
     
     func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
         let page = Int(scrollView.contentOffset.x / scrollView.bounds.width)
         self.videoPageControl.currentPage = page
         self.updateButtonStates()
     }
}
//MARK: ---------- ui --------

extension OnboardingViewController {
    
    private func setOnboardingScreenUI() {
        self.setOnBoardingCV()
        self.appBGView.setGradientBackground()
        
        self.video1to2.layer.cornerRadius = 25
        self.video1to2.backgroundColor = .pinkPrimaryColor
        self.video1to2.setTitle(APPConstants.nextTitle, for: .normal)
        self.video1to2.setTitleColor(.white, for: .normal)
        self.video1to2.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        
        self.nextVideoBtn.layer.cornerRadius = 25
        self.nextVideoBtn.backgroundColor = .pinkPrimaryColor
        self.nextVideoBtn.setTitle(APPConstants.nextVideoTitle, for: .normal)
        self.nextVideoBtn.setTitleColor(.white, for: .normal)
        self.nextVideoBtn.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        
        self.previousVideoBtn.layer.cornerRadius = 25
        self.previousVideoBtn.layer.borderColor = UIColor.pinkPrimaryColor.cgColor
        self.previousVideoBtn.layer.borderWidth = 1
        self.previousVideoBtn.backgroundColor = .white
        self.previousVideoBtn.setTitle(APPConstants.previousTitle, for: .normal)
        self.previousVideoBtn.setTitleColor(.pinkPrimaryColor, for: .normal)
        self.previousVideoBtn.titleLabel?.font = UIFont(name: Fonts.urbanistSemiBold, size: 16)
        
        self.videoPageControl.numberOfPages = videoNames.count
        self.videoPageControl.currentPage = 0
        self.videoPageControl.pageIndicatorTintColor = .lightGreyColor
        self.videoPageControl.currentPageIndicatorTintColor = .pinkPrimaryColor
    }
    
    private func setOnBoardingCV() {
        
        self.onboardingCV.delegate = self
        self.onboardingCV.dataSource = self
        self.onboardingCV.isPagingEnabled = true
        self.onboardingCV.register(VideoPlayerCVCell.nibFile, forCellWithReuseIdentifier: VideoPlayerCVCell.reUseIdentifier)
        self.onboardingCV.isScrollEnabled = true
        self.onboardingCV.layer.cornerRadius = 15
    }
    
    private func updateButtonStates() {
        
        switch currentPage {
            
        case 0:
            self.video1to2.isHidden = false
            self.buttonsView.isHidden = true
            
        case 1,2:
            self.video1to2.isHidden = true
            self.buttonsView.isHidden = false
        
        case 3:
            self.video1to2.isHidden = true
            self.buttonsView.isHidden = false
            
        default:
            break
        }
    }
}
