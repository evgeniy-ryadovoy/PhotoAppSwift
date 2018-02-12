//
//  LocalStorageManager.swift
//  PhotoTestApp
//
//  Created by Evgeniy on 11/02/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

let fileName = "photos.dat"

class LocalStorageManager: NSObject {

    private let concurrentPhotoQueue = DispatchQueue(
                    label: "com.testPhotoApp.photoQueue",
                    attributes: .concurrent)
    weak var delegate: LocalStorageManagerDelegate?

    private var error: Error?
    private var photosToSaveCount = 0

    private func getFilePath(fileName: String) -> URL? {
        let filePath = try? FileManager.default.url(for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true).appendingPathComponent(fileName)
        return filePath
    }

    func save(selectedPhotos photos: [Photo]) {
        guard let fileURL = getFilePath(fileName: fileName) else { return }
        let data = NSKeyedArchiver.archivedData(withRootObject: photos)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print(error)
        }
    }

    func getSavedPhotos() -> [Photo] {

        guard let fileURL = getFilePath(fileName: fileName),
              let data = try? Data(contentsOf: fileURL),
              let photos = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Photo] else { return [] }

        return photos
    }

    func saveToPhotoLibrary(photos: [Photo]) {

        self.photosToSaveCount = photos.count

        for photo in photos {

            concurrentPhotoQueue.async {
                UIImageWriteToSavedPhotosAlbum(photo.image!, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        concurrentPhotoQueue.async(flags: .barrier) {
            self.photosToSaveCount -= 1

            if let error = error {

                if self.error == nil {
                    self.error = error
                }

                print(error.description)
            }

            if self.photosToSaveCount == 0 {

                if self.error != nil {
                    // something wrong
                    self.delegate?.didSavePhotosToLibrary(error: error)
                } else {
                    // saved successfully
                    self.delegate?.didSavePhotosToLibrary(error: nil)
                }
            }
        }
    }
}

protocol LocalStorageManagerDelegate: NSObjectProtocol {
    func didSavePhotosToLibrary(error: Error?)
}
