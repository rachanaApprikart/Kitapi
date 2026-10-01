//
//  Image extension.swift
//  Kitapi
//
//  Created by Suneel on 28/05/26.
//

import Foundation
import UIKit


extension UIImageView {
    
    func loadImage(from urlString: String?, placeholder: UIImage? = AppImages.boy_avatar_1) {
        
        // Set placeholder immediately
        self.image = placeholder
        
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
    }
}
