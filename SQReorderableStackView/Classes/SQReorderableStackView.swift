//
//  SQReorderableStackView.swift
//  Squad
//
//  Created by Mark Murray on 4/15/16.
//  Copyright © 2016 JoinUs, Inc. All rights reserved.
//
//  Based on APRedorderableStackView by Clay Ellis
//  https://github.com/clayellis/APReorderableStackView/blob/master/ReorderStackView/APRedorderableStackView.swift

import UIKit

@objc
public protocol SQReorderableStackViewDelegate {
    
    /// called when a subview is "picked up" by the user
    @objc optional func stackViewDidBeginReordering(_ stackView: SQReorderableStackView)
    
    /// Whenever a user drags a subview for a reordering, the delegate is told whether the direction
    /// was forward (left/down) or backward (right/up), as well as what the max and min X or Y values are of the subview
    @objc optional func stackView(_ stackView: SQReorderableStackView, didDragToReorderInForwardDirection forward: Bool, maxPoint: CGPoint, minPoint: CGPoint)
    
    /// didReorderArrangedSubviews - called when reordering ends only if the selected subview's index changed during reordering
    @objc optional func stackViewDidReorderArrangedSubviews(_ stackView: SQReorderableStackView, startIndex: Int, endIndex: Int)
    
    /// didEndReordering - called when reordering ends
    @objc optional func stackViewDidEndReordering(_ stackView: SQReorderableStackView, startIndex: Int, endIndex: Int)
    
    /// called when reordering is cancelled
    @objc optional func stackViewDidCancelReordering(_ stackView: SQReorderableStackView)
    
    /// Tells the ReorderableStackView whether or not the pressed subview may be picked up.
    @objc optional func stackView(_ stackView: SQReorderableStackView, canReorderSubview subview: UIView, atIndex index: Int) -> Bool
    
    /// Tells the ReorderableStackView whether or not the held subview can take the spot at which is being held.
    @objc optional func stackView(_ stackView: SQReorderableStackView, shouldAllowSubview subview: UIView, toMoveToIndex index: Int) -> Bool
}

public class SQReorderableStackView: UIStackView, UIGestureRecognizerDelegate {
    
    /// Whether or not the subviews can be picked and reordered.
    public var reorderingEnabled = true {
        didSet {
            setReorderingEnabled(reorderingEnabled)
        }
    }
    
    /// The delegate for reordering.
    public weak var reorderDelegate: SQReorderableStackViewDelegate?
    
    fileprivate var longPressGRS = [UILongPressGestureRecognizer]()
    
    fileprivate var temporaryView: UIView!
    fileprivate var actualView: UIView!
    
    fileprivate var reordering = false
    fileprivate var finalReorderFrame: CGRect!
    fileprivate var originalPosition: CGPoint!
    fileprivate var pointForReordering: CGPoint!
    fileprivate var startIndex: Int!
    fileprivate var endIndex: Int!
    
    /// Whether or not to apply `clipsToBounds = true` to all of the subviews during reordering. Default is `false`.
    /// The corner radii feature was no longer working and has been removed.
    @available(*, deprecated)
    public var clipsToBoundsWhileReordering = false
    
    /// The cornerRadius to apply to subviews during reordering. clipsToBoundsWhileReordering must be `true`. Default is `0`
    /// The corner radii feature was no longer working and has been removed.
    @available(*, deprecated)
    public var cornerRadii: CGFloat = 0
    
    /// The relative scale of the held view's snapshot during reordering to its subview's canonical size. Default is `1.1`
    public var temporaryViewScale: CGFloat = 1.1
    
    /// The releative scale of the other subviews's size during reordering. Default is `0.95`
    public var otherViewsScale: CGFloat = 0.95
    
    /// The alpha of the held view's snapshot curing reordering. Defaults is `0.9`
    public var temporaryViewAlpha: CGFloat = 0.9
    
    /// The gap created once the long press drag is triggered. Default is `5`
    public var dragHintSpacing: CGFloat = 5
    
    /// The longPress duration for activating reordering. Default is `0.2` seconds
    public var longPressMinimumPressDuration = 0.2 {
        didSet {
            updateMinimumPressDuration()
        }
    }
    
    /// Determines whether or not the axis is horizontal.
    public var isHorizontal: Bool {
        return axis == .horizontal
    }
    
    /// Determines whether or not the axis is vertical.
    public var isVertical: Bool {
        return axis == .vertical
    }
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        for arrangedSubview in arrangedSubviews {
            addLongPressGestureRecognizerForReorderingToView(arrangedSubview)
        }
    }
    
    // MARK:- Reordering Methods

    override public func addArrangedSubview(_ view: UIView) {
        super.addArrangedSubview(view)
        addLongPressGestureRecognizerForReorderingToView(view)
    }
    
    fileprivate func addLongPressGestureRecognizerForReorderingToView(_ view: UIView) {
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGR.delegate = self
        longPressGR.minimumPressDuration = longPressMinimumPressDuration
        longPressGR.isEnabled = reorderingEnabled
        view.addGestureRecognizer(longPressGR)
        
        longPressGRS.append(longPressGR)
    }
    
    fileprivate func setReorderingEnabled(_ enabled: Bool) {
        for longPressGR in longPressGRS {
            longPressGR.isEnabled = enabled
        }
    }
    
    fileprivate func updateMinimumPressDuration() {
        for longPressGR in longPressGRS {
            longPressGR.minimumPressDuration = longPressMinimumPressDuration
        }
    }
    
    @objc internal func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        
        switch gr.state {
        case .possible:
            break
        case .began:
            actualView = gr.view!
            startIndex = indexOfArrangedSubview(actualView)
            
            if let canReorder = reorderDelegate?.stackView?(self, canReorderSubview: actualView, atIndex: startIndex) {
                if (canReorder == false) {
                    finalReorderFrame = actualView.frame;
                    gr.cancel()
                    return
                }
            }
            
            reordering = true
            reorderDelegate?.stackViewDidBeginReordering?(self)
            
            originalPosition = gr.location(in: self)
            if isHorizontal {
                originalPosition.x -= dragHintSpacing
            } else {
                originalPosition.y -= dragHintSpacing
            }
            pointForReordering = originalPosition
            prepareForReordering()
            
        case .changed:
            // Drag the temporaryView
            let newLocation = gr.location(in: self)
            let offset = isHorizontal ? newLocation.x - originalPosition.x : newLocation.y - originalPosition.y
            let translation = isHorizontal ? CGAffineTransform(translationX: offset, y: 0) : CGAffineTransform(translationX: 0, y: offset)
            let scale = CGAffineTransform(scaleX: temporaryViewScale, y: temporaryViewScale)
            temporaryView.transform = scale.concatenating(translation)
            
            let maxXorY = isHorizontal ? temporaryView.frame.maxX : self.temporaryView.frame.maxY
            let midXorY = isHorizontal ? temporaryView.frame.midX : self.temporaryView.frame.midY
            let minXorY = isHorizontal ? temporaryView.frame.minX : self.temporaryView.frame.minY
            let index = indexOfArrangedSubview(actualView)
            
            let floatForReordering = isHorizontal ? pointForReordering.x : pointForReordering.y
            let maxPoint = isHorizontal ? CGPoint(x: maxXorY, y: 0) : CGPoint(x: 0, y: maxXorY)
            let minPoint = isHorizontal ? CGPoint(x: minXorY, y: 0) : CGPoint(x: 0, y: minXorY)
            
            if midXorY > floatForReordering {
                // Dragging the view left
                let nextIndex = index + 1
                if let moveAllowed = reorderDelegate?.stackView?(self, shouldAllowSubview: actualView, toMoveToIndex: nextIndex) {
                    if !moveAllowed {
                        return
                    }
                }
                
                reorderDelegate?.stackView?(self, didDragToReorderInForwardDirection: false, maxPoint: maxPoint, minPoint: minPoint)
                
                if let nextView = getNextViewInStack(usingIndex: index) {
                    let nextViewFrameMidXorY = isHorizontal ? nextView.frame.midX : nextView.frame.midY
                    if midXorY > nextViewFrameMidXorY {
                        
                        // Swap the two arranged subviews
                        UIView.animate(withDuration: 0.2, animations: {
                            self.insertArrangedSubview(nextView, at: index)
                            self.insertArrangedSubview(self.actualView, at: index + 1)
                        })
                        finalReorderFrame = actualView.frame
                        
                        if isHorizontal {
                            pointForReordering.x = actualView.frame.midX
                        } else {
                            pointForReordering.y = actualView.frame.midY
                        }
                    }
                }
                
            } else {
                // Dragging the view right
                let previousIndex = index - 1
                if let moveAllowed = reorderDelegate?.stackView?(self, shouldAllowSubview: actualView, toMoveToIndex: previousIndex) {
                    if !moveAllowed {
                        return
                    }
                }
                
                reorderDelegate?.stackView?(self, didDragToReorderInForwardDirection: true, maxPoint: maxPoint, minPoint: minPoint)
                
                if let previousView = getPreviousViewInStack(usingIndex: index) {
                    let previousViewFrameMidXorY = isHorizontal ? previousView.frame.midX : previousView.frame.midY
                    if midXorY < previousViewFrameMidXorY {
                        
                        // Swap the two arranged subviews
                        UIView.animate(withDuration: 0.2, animations: {
                            self.insertArrangedSubview(previousView, at: index)
                            self.insertArrangedSubview(self.actualView, at: index - 1)
                        })
                        finalReorderFrame = actualView.frame
                        
                        if isHorizontal {
                            pointForReordering.x = actualView.frame.midX
                        } else {
                            pointForReordering.y = actualView.frame.midY
                        }
                    }
                }
            }
            
        case .ended, .failed:
            
            cleanupUpAfterReordering()
            reordering = false
            endIndex = indexOfArrangedSubview(actualView)
            if startIndex != endIndex {
                reorderDelegate?.stackViewDidReorderArrangedSubviews?(self, startIndex: startIndex, endIndex: endIndex)
            }
            reorderDelegate?.stackViewDidEndReordering?(self, startIndex: startIndex, endIndex: endIndex)
            
        case .cancelled:
            reorderDelegate?.stackViewDidCancelReordering?(self)
        }
    }
    
    fileprivate func prepareForReordering() {
        
        //hide shadow
        let didClip = actualView.clipsToBounds
        actualView.clipsToBounds = true
        
        // Configure the temporary view
        temporaryView = actualView.snapshotView(afterScreenUpdates: true)
        
        //reset actualView and copy shadow
        actualView.clipsToBounds = didClip
        temporaryView.layer.shadowRadius = actualView.layer.shadowRadius
        temporaryView.layer.shadowPath = actualView.layer.shadowPath
        temporaryView.layer.shadowColor = actualView.layer.shadowColor
        temporaryView.layer.shadowOffset = actualView.layer.shadowOffset
        temporaryView.layer.shadowOpacity = actualView.layer.shadowOpacity
        temporaryView.layer.cornerRadius = actualView.layer.cornerRadius
        
        temporaryView.frame = actualView.frame
        finalReorderFrame = actualView.frame
        addSubview(temporaryView)
        
        actualView.alpha = 0
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            
            self.styleViewsForReordering()
            
            }, completion: nil)
    }
    
    fileprivate func cleanupUpAfterReordering() {
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            
            self.styleViewsForEndReordering()
            
            }, completion: { (Bool) -> Void in
                // Hide the temporaryView, show the actualView
                self.temporaryView.removeFromSuperview()
                self.actualView.alpha = 1
        })
        
    }
    
    // MARK:- View Styling Methods
    
    fileprivate func styleViewsForReordering() {
        
        let scale = CGAffineTransform(scaleX: temporaryViewScale, y: temporaryViewScale)
        let translation = isHorizontal ? CGAffineTransform(translationX: 0, y: dragHintSpacing) : CGAffineTransform(translationX: dragHintSpacing, y: 0)
        temporaryView.transform = scale.concatenating(translation)
        temporaryView.alpha = temporaryViewAlpha
        
        for subview in arrangedSubviews {
            if subview != actualView {
                subview.transform = CGAffineTransform(scaleX: otherViewsScale, y: otherViewsScale)
            }
        }
    }
    
    fileprivate func styleViewsForEndReordering() {
        
        // Return drag view to original appearance
        temporaryView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        temporaryView.frame = finalReorderFrame
        temporaryView.alpha = 1.0
        
        // Return other arranged subviews to original appearances
        for subview in arrangedSubviews {
            UIView.animate(withDuration: 0.3, animations: {
                subview.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        }
    }
    
    // MARK:- Stack View Helper Methods
    
    fileprivate func indexOfArrangedSubview(_ view: UIView) -> Int {
        for (index, subview) in arrangedSubviews.enumerated() {
            if view == subview {
                return index
            }
        }
        return 0
    }
    
    fileprivate func getPreviousViewInStack(usingIndex index: Int) -> UIView? {
        guard index > 0 else { return nil }
        return arrangedSubviews[index - 1]
    }
    
    fileprivate func getNextViewInStack(usingIndex index: Int) -> UIView? {
        guard index != arrangedSubviews.count - 1 else { return nil }
        return arrangedSubviews[index + 1]
    }
    
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !reordering
    }
    
}

fileprivate extension UIGestureRecognizer {
    func cancel() {
        isEnabled = false
        isEnabled = true
    }
}
