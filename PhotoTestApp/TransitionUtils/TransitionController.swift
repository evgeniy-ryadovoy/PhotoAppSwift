/*
    The TransitionController class conforms to UIViewControllerAnimatedTransitioning.
    This class also manages the gesture recognizer used to initiate the custom interactive pop transition.
*/

import UIKit

let springWithDumping: CGFloat = 0.85
let initialSpringVelocity: CGFloat = 0.8
let transitionDurationTime: TimeInterval = 1

class TransitionController: NSObject, UIViewControllerAnimatedTransitioning {

    private var image: UIImage?
    private weak var fromDelegate: ImageTransitionProtocol?
    private weak var toDelegate: ImageTransitionProtocol?

    // MARK: Setup Methods
    func setupImageTransition(image: UIImage, fromDelegate: ImageTransitionProtocol, toDelegate: ImageTransitionProtocol) {
        self.image = image
        self.fromDelegate = fromDelegate
        self.toDelegate = toDelegate
    }

    // MARK: UIViewControllerAnimatedTransitioning
    // 1: Set animation speed
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDurationTime
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 2: Get view controllers involved
        let containerView = transitionContext.containerView
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let toVC   = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }

        // 3: Set the destination view controllers frame
        toVC.view.frame = fromVC.view.frame

        // 4: Create transition image view
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill

        if let fromDelegate = fromDelegate {
            imageView.frame = fromDelegate.imageWindowFrame()
        } else {
            imageView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        }

        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        fromDelegate?.transitionSetup()
        toDelegate?.transitionSetup()

        // 5: Create from screen snapshot
        guard let fromSnapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else { return }

        fromSnapshot.frame = fromVC.view.frame
        containerView.addSubview(fromSnapshot)

        // 6: Create to screen snapshot
        guard let toSnapshot = toVC.view.snapshotView(afterScreenUpdates: true) else { return }

        toSnapshot.frame = fromVC.view.frame
        containerView.addSubview(toSnapshot)
        toSnapshot.alpha = 0

        // 7: Bring the image view to the front and get the final frame
        containerView.bringSubview(toFront: imageView)
        var toFrame: CGRect

        if let toDelegate = self.toDelegate {
            toFrame = toDelegate.imageWindowFrame()
        } else {
            toFrame = CGRect(x: 0, y: 0, width: 0, height: 0)
        }

        // 8: Animate change
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0,
                usingSpringWithDamping: springWithDumping,
                initialSpringVelocity: initialSpringVelocity,
                options: .curveEaseOut,
                animations: {
                    toSnapshot.alpha = 1
                    imageView.frame = toFrame

                },
                completion: { [weak self] (_) in

                    if let toDelegate = self?.toDelegate, let fromDelegate = self?.fromDelegate {
                        toDelegate.transitionCleanup()
                        fromDelegate.transitionCleanup()
                    }

                    // 9: Remove transition views
                    imageView.removeFromSuperview()
                    fromSnapshot.removeFromSuperview()
                    toSnapshot.removeFromSuperview()

                    // 10: Complete transition
                    if !transitionContext.transitionWasCancelled {
                        containerView.addSubview(toVC.view)
                    }
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
        )
    }
}

protocol ImageTransitionProtocol: NSObjectProtocol {
    func transitionSetup()
    func transitionCleanup()
    func imageWindowFrame() -> CGRect
}
