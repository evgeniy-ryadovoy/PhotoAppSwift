/*
    The ViewController is a basic view controller created to display grid presentation of a loaded photos.
*/

import UIKit

private let reuseIdentifier = "PhotoCell"
private let selectedAlpha: CGFloat = 0.2
private let defaultAlpha: CGFloat  = 1.0

class ViewController: AnimatedCollectionControllerPrototype {

    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.photoManager.delegate = self
        leftBarButtonItem = self.navigationItem.leftBarButtonItem

        NotificationCenter.default.addObserver(
                self,
                selector: #selector(contentChangedNotification(notification:)),
                name: NSNotification.Name(rawValue: photoManagerContentUpdatedNotification),
                object: nil)
    }

    // iOS 11 bug. As usual...
    // https://stackoverflow.com/questions/47805224/uibarbuttonitem-will-be-always-highlight-when-i-click-it
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.leftBarButtonItem?.isEnabled = true
    }

    // MARK: - Notification handlers
    @objc func contentChangedNotification(notification: NSNotification) {

        /* Reload only unique cell. It can improve performance for big collection view
           We can specify section, cell, etc */

        if let userInfo = notification.userInfo, let photo = userInfo["photo"] {
            let nsArray = self.photos[0] as NSArray
            let index = nsArray.indexOfObjectIdentical(to: photo)

            self.collectionView.performBatchUpdates({
                self.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
            }, completion: nil)
        }
    }

    // MARK: Select mode
    @IBAction func enableSelectMode(_ sender: Any) {
        selectMode(enabled: true)
    }

    override func doneSelecting() {
        selectMode(enabled: false)
        var photosToSave: [Photo] = []

        for indexPath in self.selectedPhotos {
            photosToSave.append(self.photos[0][indexPath.row])
        }

        deselectAllItems()
        self.selectedPhotos.removeAll()
        self.photoManager.save(selectedPhotos: photosToSave)
    }
}

// MARK: Search Bar
extension ViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        if let search = searchBar.text {
            self.showActivityIndicator()
            self.photoManager.getPictures(topic: search)
        }
    }
}

// MARK: PhotoDataManagerDelegate
extension ViewController: PhotoDataManagerDelegate {

    func didReceive(photos: [Photo]) {

        if self.photos.isEmpty {
            self.photos.append(photos)
        } else {
            self.photos[0].append(contentsOf: photos)
        }

        DispatchQueue.main.async {
            self.hideActivityIndicator()
            self.collectionView.reloadData()
        }
    }

    func receivePhotosFailedWith(error: Error) {
        let error = error as NSError

        DispatchQueue.main.async {
            self.hideActivityIndicator()
            UIAlertController.showSimpleAlert(withTitle: "Error", message: error.localizedDescription)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if photos.isEmpty {
            return 0
        }

        return self.photos[0].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell

        // Configure the cell
        cell.imageView.contentMode = .scaleAspectFill
        let photo = self.photos[0][indexPath.row]

        switch photo.statusThumbnail {

        case .goodToGo:
            cell.imageView.image = (indexPath == selectedIndex && hideSelectedCell) ? nil : photo.image
        case .downloading:
            cell.imageView.image = UIImage(named: "photoDownloading")
        case .failed:
            cell.imageView.image = UIImage(named: "photoDownloadError")
        }

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
extension ViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photo = self.photos[0][indexPath.row]

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
