//
//  Photo.swift
//  PhotoTestApp
//
//  Created by Evgeniy on 07/02/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

typealias PhotoDownloadCompletionBlock = (_ image: UIImage?, _ error: NSError?) -> Void
typealias PhotoDownloadProgressBlock = (_ completed: Int, _ total: Int) -> Void

enum PhotoStatus: Int {
    case downloading
    case goodToGo
    case failed
}

private let scale = UIScreen.main.scale
private let cellSize = CGSize(width: 80, height: 80)
private let thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)

protocol Photo {
    var statusImage: PhotoStatus { get }
    var statusThumbnail: PhotoStatus { get }
    var image: UIImage? { get }
    var thumbnail: UIImage? { get }
    var date: Date { get }
}

class DownloadPhoto: NSObject, Photo, NSCoding {
    var statusImage: PhotoStatus = .downloading
    var statusThumbnail: PhotoStatus = .downloading
    var image: UIImage?
    var thumbnail: UIImage?
    var date: Date = Date()

    private var photoUrl: URL

    init(photoUrl: URL, completion: PhotoDownloadCompletionBlock!) {
        self.photoUrl = photoUrl
        super.init()
        downloadImage(completion)
    }

    convenience init(photoUrl: URL) {
        self.init(photoUrl: photoUrl, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.statusImage = PhotoStatus(rawValue: aDecoder.decodeInteger(forKey: "statusImage"))!
        self.statusThumbnail = PhotoStatus(rawValue: aDecoder.decodeInteger(forKey: "statusThumbnail"))!
        self.photoUrl = aDecoder.decodeObject(forKey: "photoURL") as! URL

        guard let imageData = aDecoder.decodeObject(forKey: "photoImage") as? Data else {
            self.image = nil
            self.thumbnail = nil
            return
        }

        self.image = UIImage(data: imageData)
        self.thumbnail = self.image?.thumbnailImage(Int(cellSize.width),
                transparentBorder: 0,
                cornerRadius: 0,
                interpolationQuality: CGInterpolationQuality.default)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.statusImage.rawValue, forKey: "statusImage")
        aCoder.encode(self.statusThumbnail.rawValue, forKey: "statusThumbnail")
        aCoder.encode(self.photoUrl, forKey: "photoURL")

        guard let image = self.image,
              let imageData = UIImageJPEGRepresentation(image, 1.0) else {
            return
        }

        aCoder.encode(imageData, forKey: "photoImage")
    }

    private func downloadImage(_ completion: PhotoDownloadCompletionBlock?) {
        let networkService = NetworkService()
        networkService.requestFromURL(requestUrl: photoUrl) { data, error in

            if let data = data {
                self.image = UIImage(data: data)
            }

            if error == nil && self.image != nil {
                self.statusImage = .goodToGo
                self.statusThumbnail = .goodToGo
            } else {
                self.statusImage = .failed
                self.statusThumbnail = .failed
            }

            self.thumbnail = self.image?.thumbnailImage(Int(cellSize.width),
                    transparentBorder: 0,
                    cornerRadius: 0,
                    interpolationQuality: CGInterpolationQuality.default)

            self.date = Date()
            completion?(self.image, error as NSError?)

            DispatchQueue.main.async {
                let center = NotificationCenter.default
                let userInfo = ["photo": self]
                center.post(name: Notification.Name(rawValue: photoManagerContentUpdatedNotification),
                        object: nil, userInfo: userInfo)
            }
         }
    }
}
