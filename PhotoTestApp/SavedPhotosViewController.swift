//
//  SavedPhotosViewController.swift
//  PhotoTestApp
//
//  Created by Evgeniy on 11/02/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

private let reuseIdentifier = "SavedPhotoCell"
private let selectedAlpha: CGFloat = 0.2
private let defaultAlpha: CGFloat  = 1.0

extension Formatter {
    static let monthMedium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLL"
        return formatter
    }()
    static let currentDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()
    static let hour12: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h"
        return formatter
    }()
    static let minute0x: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter
    }()
    static let amPM: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter
    }()
}
extension Date {
    var monthMedium: String { return Formatter.monthMedium.string(from: self) }
    var currentDay: String { return Formatter.currentDay.string(from: self) }
    var hour12: String { return Formatter.hour12.string(from: self) }
    var minute0x: String { return Formatter.minute0x.string(from: self) }
    var amPM: String { return Formatter.amPM.string(from: self) }
}

class SavedPhotosViewController: AnimatedCollectionControllerPrototype {

    private let localStorage = LocalStorageManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        let savedPhotos = self.localStorage.getSavedPhotos()
        self.photos = sortedPhotosByDate(photos: savedPhotos)
        self.collectionView.reloadData()
        self.localStorage.delegate = self
    }

    // MARK: Select mode
    @IBAction func enableSelectMode(_ sender: Any) {
        selectMode(enabled: true)
    }

    override  func doneSelecting() {
        selectMode(enabled: false)
        self.selectedPhotos.removeAll()
        deselectAllItems()
    }

    @IBAction func deleteSelectedPhotos(_ sender: Any) {
        selectMode(enabled: false)
        let sorted = self.selectedPhotos.sorted().reversed()

        for indexPath in sorted {
            self.photos[indexPath.section].remove(at: indexPath.row)

            if self.photos[indexPath.section].isEmpty {
                self.photos.remove(at: indexPath.section)
            }
        }

        self.collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: self.selectedPhotos)
        }, completion: nil)

        self.selectedPhotos.removeAll()
        let remainPhotos: [Photo] = self.photos.flatMap { $0 }
        self.photoManager.save(selectedPhotos: remainPhotos)
    }

    @IBAction func saveSelectedPhotos(_ sender: Any) {
        showActivityIndicator()
        selectMode(enabled: false)
        var photosToSave: [Photo] = Array()

        for indexPath in self.selectedPhotos {
            photosToSave.append(self.photos[indexPath.section][indexPath.row])
        }

        self.localStorage.saveToPhotoLibrary(photos: photosToSave)
        self.selectedPhotos.removeAll()
        deselectAllItems()
    }

    // MARK: - Convenience
    func sortedPhotosByDate(photos: [Photo]) -> [[Photo]] {

        if photos.isEmpty { return Array() }

        let sorted = photos.sorted(by: { $0.date < $1.date })
        let calendar = NSCalendar.current
        var previous: Photo = sorted[0]
        var result: [[Photo]] = Array()
        result.append(Array())
        var index: Int = 0

        for photo in sorted {

            let date1 = calendar.startOfDay(for: photo.date)
            let date2 = calendar.startOfDay(for: previous.date)
            let components = calendar.dateComponents([.day], from: date1, to: date2)

            let days = components.day

            if days == 0 {
                result[index].append(photo)
            } else {
                index += 1
                result.append(Array())
            }

            previous = photo
        }

        return result
    }
}

// MARK: - UICollectionViewDataSource
extension SavedPhotosViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.photos.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos[section].count
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                withReuseIdentifier: "SectionHeader", for: indexPath) as! SectionHeaderCollectionReusableView

        let date = self.photos[indexPath.section][0].date
        let month = date.monthMedium
        let day   = date.currentDay

        header.headerLabel.text = NSString(format: "%@ %@", month, day) as String

        return header
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell

        // Configure the cell
        cell.imageView.contentMode = .scaleAspectFill
        let photo = self.photos[indexPath.section][indexPath.row]
        cell.imageView.image =  photo.image

        if self.selectedPhotos.contains(indexPath) {
            cell.isSelected = true
        } else {
            cell.isSelected = false
        }

        cell.alpha = (cell.isSelected) ? selectedAlpha : defaultAlpha

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SavedPhotosViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = self.photos[indexPath.section][indexPath.row]

        if photo.statusImage != .goodToGo {
            return
        }

        if self.selectModeOn {
            guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else { return }

            self.selectedPhotos.append(indexPath)
            cell.alpha = selectedAlpha
        } else {
            selectedIndex = indexPath
            let detailViewController = DetailViewController()
            detailViewController.flowLayout.itemSize = view.bounds.size
            detailViewController.photos = self.photos
            detailViewController.currentPhotoIndex = indexPath
            detailViewController.galleryDelegate = self
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let deselectedCell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else { return }

        if let index = self.selectedPhotos.index(of: indexPath) {
            self.selectedPhotos.remove(at: index)
        }

        deselectedCell.alpha = defaultAlpha
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

// MARK: - LocalStorageManagerDelegate
extension SavedPhotosViewController: LocalStorageManagerDelegate {

    func didSavePhotosToLibrary(error: Error?) {
        let title = (error != nil) ? "Error" : "Success"
        let text  = (error != nil) ? "Something wrong. Check permissions" : "Saved successfully"

        DispatchQueue.main.async {
            self.hideActivityIndicator()
            UIAlertController.showSimpleAlert(withTitle: title, message: text)
        }
    }
}
