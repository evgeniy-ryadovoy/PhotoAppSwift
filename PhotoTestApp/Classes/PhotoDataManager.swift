//
//  PhotoDataManager.swift
//  PhotoTestApp
//
//  Created by Evgeniy on 05/02/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

let photoManagerContentUpdatedNotification = "com.phototestapp.photoManagerContentUpdated"

struct Constants {
    static let googleEndPoint = "https://www.googleapis.com/customsearch/v1"
    static let googleApiKey   = "AIzaSyARJ21szXm20fsBNv4awqeoF4zqGpLKTlU"
    static let googleCxKey    = "011667090051392344973:rl-jic4chpm"
}

class PhotoDataManager: NSObject {

    private let imageSearchUrl = Constants.googleEndPoint
                + "?key=" + Constants.googleApiKey
                + "&cx=" + Constants.googleCxKey
                + "&searchType=image&alt=json&q="

    private var networkService: NetworkService
    private var images = NSMutableArray()
    private var photos = NSMutableArray()
    private var storageManager = LocalStorageManager()
    weak var delegate: PhotoDataManagerDelegate?

    override init() {
        networkService = NetworkService()
        super.init()
    }

    func getPictures(topic: String) {
        guard let topic = topic.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlFragmentAllowed) else { return }
        let stringUrl = imageSearchUrl + topic

        if let url = URL(string: stringUrl) {

            networkService.requestFromURL(requestUrl: url) { data, error in

                if let error = error {
                    self.delegate?.receivePhotosFailedWith(error: error)
                } else {
                    self.parseData(data: data)
                }
            }
        } else {
            let errorString = String.localizedStringWithFormat(NSLocalizedString("URL Error",
                    comment: "Something wrong with your request."))

            let userInfo: Dictionary = [NSLocalizedDescriptionKey: errorString]
            let error = NSError(domain: "HTTP", code: 0, userInfo: userInfo)
            self.delegate?.receivePhotosFailedWith(error: error)
        }
    }

    private func parseData(data: Data?) {
        // Data is nil
        guard let receivedData = data else {
            return
        }

        let parsedObject = try? JSONSerialization.jsonObject(with: receivedData, options: [])

        if let dictionary = parsedObject as? [String: Any] {

            // No items for request
            guard let imagesArray = dictionary["items"] as? [Any]  else {
                self.delegate?.didReceive(photos: [])
                return
            }

            self.images.removeAllObjects()

            for case let imageItem as [String: Any] in imagesArray {

                if let link = imageItem["link"] as? String {
                    self.images.add(link)
                }
            }

            print(self.images)
            self.getPhotosByUrls(photoUrls: self.images as! [String])
        }
    }

    private func getPhotosByUrls(photoUrls: [String]) {
        photos.removeAllObjects()

        for address in photoUrls {
            let url = URL(string: address)
            let photo = DownloadPhoto(photoUrl: url!) { _, error in

                if let error = error {
                    self.delegate?.receivePhotosFailedWith(error: error)
                }
            }

            photos.add(photo)
        }

        self.delegate?.didReceive(photos: photos as! [Photo])
    }

    func save(selectedPhotos photos: [Photo]) {
        self.storageManager.save(selectedPhotos: photos)
    }

    func getSavedPhotos() -> [Photo] {
        return self.storageManager.getSavedPhotos()
    }
}

protocol PhotoDataManagerDelegate: AnyObject {
    func didReceive(photos: [Photo])
    func receivePhotosFailedWith(error: Error)
}
