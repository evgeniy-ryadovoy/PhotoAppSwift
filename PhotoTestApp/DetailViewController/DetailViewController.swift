/*
    The DetailViewController is a basic view controller created to display one-up presentation of a single photo.
*/

import UIKit

private let reuseIdentifier = "Cell"

class DetailViewController: UICollectionViewController {

    weak var galleryDelegate: GalleryDelegate?
    var photos: [[Photo]] = []
    var currentPhotoIndex: IndexPath = [0, 0]

    // MARK: Initializers
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var flowLayout: UICollectionViewFlowLayout {
        return collectionViewLayout as! UICollectionViewFlowLayout
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        if let collectionView = self.collectionView {
            collectionView.register(DetailCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            collectionView.backgroundColor = UIColor.clear
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recalculateItemSize(inBoundingSize: self.view.bounds.size)
        self.automaticallyAdjustsScrollViewInsets = false
        guard let collectionView = self.collectionView else { return }

        collectionView.isPagingEnabled = true
        collectionView.frame = view.frame.insetBy(dx: 0.0, dy: 0.0)
        let xOffset = CGFloat(getOffsetIndex(from: currentPhotoIndex)) * collectionView.frame.size.width
        collectionView.contentOffset = CGPoint(x: xOffset, y: 0)
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos[section].count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                for: indexPath) as! DetailCell

        let photo = self.photos[indexPath.section][indexPath.row]
        cell.imageView.image = photo.image
        return cell
    }

    // MARK: UICollectionViewDelegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let collectionView = self.collectionView else { return }

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint) else { return }
        currentPhotoIndex = visibleIndexPath
        galleryDelegate?.updateSelectedIndex(newIndex: visibleIndexPath)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {

        guard let indexPath = collectionView.indexPathsForVisibleItems.last,
              let layoutAttributes = flowLayout.layoutAttributesForItem(at: indexPath) else {
            return proposedContentOffset
        }

        return CGPoint(x: layoutAttributes.center.x - (layoutAttributes.size.width / 2.0) - (flowLayout.minimumLineSpacing / 2.0), y: 0)
    }

    // MARK: Utility Methods
    private func getCurrentPageIndex() -> Int {

        guard let collectionView = self.collectionView else {
            return 0
        }

        return Int(round(collectionView.contentOffset.x / collectionView.frame.size.width))
    }

    private func getOffsetIndex(from indexPath: IndexPath) -> Int {
        var count = 0

        //if currentPhotoIndex.section > 0 {

        for column in 0..<indexPath.section {
            count += self.photos[column].count
        }
        //}

        count += indexPath.row
        return count
    }

    private func recalculateItemSize(inBoundingSize size: CGSize) {
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = size
    }
}

// MARK: ImageTransitionProtocol
extension DetailViewController: ImageTransitionProtocol {

    func transitionSetup() {
        self.collectionView?.isHidden = true
    }

    // 2; unhide images and set correct image to be showing
    func transitionCleanup() {

        guard let collectionView = collectionView else {
            return
        }

        collectionView.isHidden = false
    }

    // 3: return the imageView window frame
    func imageWindowFrame() -> CGRect {

        guard let collectionView = self.collectionView else {
            return CGRect()
        }

        let photo = photos[currentPhotoIndex.section][currentPhotoIndex.row]

        guard let photoImage = photo.image else {
            return CGRect()
        }

        let collectionWindowFrame = collectionView.superview!.convert(collectionView.frame, to: nil)
        let collectionViewRatio   = collectionView.frame.size.width / collectionView.frame.size.height
        let imageRatio = photoImage.size.width / photoImage.size.height
        let touchesSides = (imageRatio > collectionViewRatio)

        if touchesSides {
            let height = collectionWindowFrame.size.width / imageRatio
            let yPoint = collectionWindowFrame.origin.y + (collectionWindowFrame.size.height - height) / 2
            return CGRect(x: collectionWindowFrame.origin.x, y: yPoint, width: collectionWindowFrame.size.width, height: height)
        } else {
            let width = collectionWindowFrame.size.height * imageRatio
            let xPoint = collectionWindowFrame.origin.x + (collectionWindowFrame.size.width - width) / 2
            return CGRect(x: xPoint, y: collectionWindowFrame.origin.y, width: width, height: collectionWindowFrame.size.height)
        }
    }
}
