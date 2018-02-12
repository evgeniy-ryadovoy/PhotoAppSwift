/*
    DetailCell is a basic UICollectionViewCell subclass to display a photo.
*/

import UIKit

class DetailCell: UICollectionViewCell {

    let imageView: UIImageView

    override init(frame: CGRect) {
        imageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: frame.size))
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true

        super.init(frame: frame)

        backgroundView = imageView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
