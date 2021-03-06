import Foundation
import AsyncDisplayKit

public final class ContextControllerSourceNode: ASDisplayNode {
    private var contextGesture: ContextGesture?
    
    public var isGestureEnabled: Bool = true {
        didSet {
            self.contextGesture?.isEnabled = self.isGestureEnabled
        }
    }
    public var activated: ((ContextGesture) -> Void)?
    public var shouldBegin: ((CGPoint) -> Bool)?
    public var customActivationProgress: ((CGFloat, ContextGestureTransition) -> Void)?
    public var targetNodeForActivationProgress: ASDisplayNode?
    
    public func cancelGesture() {
        self.contextGesture?.cancel()
        self.contextGesture?.isEnabled = false
        self.contextGesture?.isEnabled = self.isGestureEnabled
    }
    
    override public func didLoad() {
        super.didLoad()
        
        let contextGesture = ContextGesture(target: self, action: nil)
        self.contextGesture = contextGesture
        self.view.addGestureRecognizer(contextGesture)
        
        contextGesture.shouldBegin = { [weak self] point in
            guard let strongSelf = self, !strongSelf.bounds.width.isZero else {
                return false
            }
            return strongSelf.shouldBegin?(point) ?? true
        }
        
        contextGesture.activationProgress = { [weak self] progress, update in
            guard let strongSelf = self, !strongSelf.bounds.width.isZero else {
                return
            }
            if let customActivationProgress = strongSelf.customActivationProgress {
                customActivationProgress(progress, update)
            } else {
                let targetNode = strongSelf.targetNodeForActivationProgress ?? strongSelf
                
                let minScale: CGFloat = (strongSelf.bounds.width - 10.0) / strongSelf.bounds.width
                let currentScale = 1.0 * (1.0 - progress) + minScale * progress
                switch update {
                case .update:
                    targetNode.layer.sublayerTransform = CATransform3DMakeScale(currentScale, currentScale, 1.0)
                case .begin:
                    targetNode.layer.sublayerTransform = CATransform3DMakeScale(currentScale, currentScale, 1.0)
                case let .ended(previousProgress):
                    let previousScale = 1.0 * (1.0 - previousProgress) + minScale * previousProgress
                    targetNode.layer.sublayerTransform = CATransform3DMakeScale(currentScale, currentScale, 1.0)
                    targetNode.layer.animateSpring(from: previousScale as NSNumber, to: currentScale as NSNumber, keyPath: "sublayerTransform.scale", duration: 0.5, delay: 0.0, initialVelocity: 0.0, damping: 90.0)
                }
            }
        }
        contextGesture.activated = { [weak self] gesture in
            if let activated = self?.activated {
                activated(gesture)
            } else {
                gesture.cancel()
            }
        }
        contextGesture.isEnabled = self.isGestureEnabled
    }
}
