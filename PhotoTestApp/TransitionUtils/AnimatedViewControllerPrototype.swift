//
//  AnimatedViewControllerPrototype.swift
//  PhotoTestApp
//
//  Created by Evgeniy on 11/02/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

class AnimatedViewControllerPrototype: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorContainer: UIView!

    private var animationController = TransitionController()
    internal var hideSelectedCell = false
    internal var selectedIndex: IndexPath = [0, 0]

    internal var photos: [[Photo]] = Array()
    internal var selectedPhotos: [IndexPath] = []

    internal var selectModeOn = false
    internal var leftBarButtonItem: UIBarButtonItem?

    internal let photoManager = PhotoDataManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navc = self.navigationController {
            navc.delegate = self
        }
    }

    // MARK: Activity Indicator
    func showActivityIndicator() {
        self.activityIndicator.startAnimating()
        self.activityIndicatorContainer.isHidden = false
    }

    func hideActivityIndicator() {
        self.activityIndicator.stopAnimating()
        self.activityIndicatorContainer.isHidden = true
    }

    // MARK: - Convenience
    internal func deselectAllItems() {

        guard let selectedItems = self.collectionView.indexPathsForSelectedItems else { return }

        for indexPath in selectedItems {
            self.collectionView.deselectItem(at: indexPath, animated: false)
        }

        self.collectionView.performBatchUpdates({
            self.collectionView.reloadItems(at: selectedItems)
        }, completion: nil)
    }

    internal func selectMode(enabled: Bool) {
        self.selectModeOn = enabled

        if enabled {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain,
                    target: self,
                    action: #selector(doneSelecting))
        } else {
            self.navigationItem.leftBarButtonItem = self.leftBarButtonItem
        }
    }

    @objc internal func doneSelecting() {
        // Override this!
    }
}

// MARK: - UINavigationControllerDelegate
extension AnimatedViewControllerPrototype: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

        if toVC is DetailViewController {
            let photoViewController = toVC as! DetailViewController
            animationController.setupImageTransition( image: photos[selectedIndex.section][selectedIndex.row].image!,
                    fromDelegate: self,
                    toDelegate: photoViewController)

            return animationController
        }

        if fromVC is DetailViewController {
            let photoViewController = fromVC as! DetailViewController
            animationController.setupImageTransition( image: photos[selectedIndex.section][selectedIndex.row].image!,
                    fromDelegate: photoViewController,
                    toDelegate: self)

            return animationController
        }

        return nil
    }
}

// MARK: ImageTransitionProtocol
extension AnimatedViewControllerPrototype: ImageTransitionProtocol {

    // 1: hide selected cell for transition snapshot
    func transitionSetup() {
        hideSelectedCell = true
        collectionView.reloadData()
    }

    // 2: unhide selected cell after transition snapshot is taken
    func transitionCleanup() {
        hideSelectedCell = false
        collectionView.reloadData()
    }

    // 3: return window frame of selected image
    func imageWindowFrame() -> CGRect {
        let attributes = collectionView.layoutAttributesForItem(at: selectedIndex)
        let cellRect = attributes!.frame
        return collectionView.convert(cellRect, to: nil)
    }
}

// MARK: GalleryDelegate
extension AnimatedViewControllerPrototype: GalleryDelegate {

    func updateSelectedIndex(newIndex: IndexPath) {
        selectedIndex = newIndex
    }
}

protocol GalleryDelegate: NSObjectProtocol {
    func updateSelectedIndex(newIndex: IndexPath)
}
