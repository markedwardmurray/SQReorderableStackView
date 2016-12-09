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
    @objc optional func didBeginReordering()
    
    /// Whenever a user drags a subview for a reordering, the delegate is told whether the direction
    /// was forward (left/down) or backward (right/up), as well as what the max and min X or Y values are of the subview
    @objc optional func didDragToReorder(inForwardDirection forward: Bool, maxPoint: CGPoint, minPoint: CGPoint)
    
    /// didReorderArrangedSubviews - called when reordering ends only if the selected subview's index changed during reordering
    @objc optional func didReorderArrangedSubviews(_ arrangedSubviews: Array<UIView>)
    
    /// didEndReordering - called when reordering ends
    @objc optional func didEndReordering()
    
    /// called when reordering is cancelled
    @objc optional func didCancelReordering()
    
    /// Tells the ReorderableStackView whether or not the pressed subview may be picked up.
    @objc optional func canReorderSubview(_ subview: UIView) -> Bool
    
    /// Tells the ReorderableStackView whether or not the held subview can take the spot at which is being held.
    @objc optional func shouldAllowSubview(_ subview: UIView, toMoveToIndex index: Int) -> Bool
}

public class SQReorderableStackView: UIStackView, UIGestureRecognizerDelegate {
    
    /// Whether or not the subviews can be picked and reordered.
    public var reorderingEnabled = false {
        didSet {
            self.setReorderingEnabled(self.reorderingEnabled)
        }
    }
    /// The delegate for reordering.
    public var reorderDelegate: SQReorderableStackViewDelegate?
    
    fileprivate var longPressGRS = [UILongPressGestureRecognizer]()
    
    fileprivate var temporaryView: UIView!
    fileprivate var actualView: UIView!
    
    fileprivate var reordering = false
    fileprivate var finalReorderFrame: CGRect!
    fileprivate var originalPosition: CGPoint!
    fileprivate var pointForReordering: CGPoint!
    fileprivate var startIndex: Int!
    fileprivate var endIndex: Int!
    
    /// Whether or not to apply `clipsToBounds = true` to all of the subviews during reordering. Default is `false`
    public var clipsToBoundsWhileReordering = false
    /// The cornerRadius to apply to subviews during reordering. clipsToBoundsWhileReordering must be `true`. Default is `0`
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
            self.updateMinimumPressDuration()
        }
    }
    
    /// Determines whether or not the axis is horizontal.
    public var isHorizontal: Bool {
        return self.axis == .horizontal
    }
    /// Determines whether or not the axis is vertical.
    public var isVertical: Bool {
        return self.axis == .vertical
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        for arrangedSubview in self.arrangedSubviews {
            self.addLongPressGestureRecognizerForReorderingToView(arrangedSubview)
        }
    }
    
    // MARK:- Reordering Methods
    // ---------------------------------------------------------------------------------------------
    override public func addArrangedSubview(_ view: UIView) {
        super.addArrangedSubview(view)
        self.addLongPressGestureRecognizerForReorderingToView(view)
    }
    
    fileprivate func addLongPressGestureRecognizerForReorderingToView(_ view: UIView) {
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGR.delegate = self
        longPressGR.minimumPressDuration = self.longPressMinimumPressDuration
        longPressGR.isEnabled = self.reorderingEnabled
        view.addGestureRecognizer(longPressGR)
        
        self.longPressGRS.append(longPressGR)
    }
    
    fileprivate func setReorderingEnabled(_ enabled: Bool) {
        for longPressGR in self.longPressGRS {
            longPressGR.isEnabled = enabled
        }
    }
    
    fileprivate func updateMinimumPressDuration() {
        for longPressGR in self.longPressGRS {
            longPressGR.minimumPressDuration = self.longPressMinimumPressDuration
        }
    }
    
    internal func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        
        if gr.state == .began {
            self.actualView = gr.view!
            self.startIndex = self.indexOfArrangedSubview(self.actualView)
            
            if let canReorder = self.reorderDelegate?.canReorderSubview?(self.actualView) {
                if (canReorder == false) {
                    self.finalReorderFrame = self.actualView.frame;
                    gr.cancel()
                    return
                }
            }
            
            self.reordering = true
            self.reorderDelegate?.didBeginReordering?()
            
            self.cornerRadii = actualView.layer.cornerRadius
            self.originalPosition = gr.location(in: self)
            self.originalPosition.x -= self.dragHintSpacing
            self.pointForReordering = self.originalPosition
            self.prepareForReordering()
            
        } else if gr.state == .changed {
            
            // Drag the temporaryView
            let newLocation = gr.location(in: self)
            let xOffset = newLocation.x - originalPosition.x
            let translation = CGAffineTransform(translationX: xOffset, y: 0)
            let scale = CGAffineTransform(scaleX: self.temporaryViewScale, y: self.temporaryViewScale)
            self.temporaryView.transform = scale.concatenating(translation)
            
            let maxXorY = self.isHorizontal ? self.temporaryView.frame.maxX : self.temporaryView.frame.maxY
            let midXorY = self.isHorizontal ? self.temporaryView.frame.midX : self.temporaryView.frame.midY
            let minXorY = self.isHorizontal ? self.temporaryView.frame.minX : self.temporaryView.frame.minY
            let index = self.indexOfArrangedSubview(self.actualView)
            
            let floatForReordering = self.isHorizontal ? self.pointForReordering.x : self.pointForReordering.y
            let maxPoint = self.isHorizontal ? CGPoint(x: maxXorY, y: 0) : CGPoint(x: 0, y: maxXorY)
            let minPoint = self.isHorizontal ? CGPoint(x: minXorY, y: 0) : CGPoint(x: 0, y: minXorY)
            
            if midXorY > floatForReordering {
                // Dragging the view left
                let nextIndex = index + 1
                if let moveAllowed = self.reorderDelegate?.shouldAllowSubview?(self.actualView, toMoveToIndex: nextIndex) {
                    if (moveAllowed == false) {
                        return
                    }
                }
                
                self.reorderDelegate?.didDragToReorder?(inForwardDirection: false, maxPoint: maxPoint, minPoint: minPoint)
                
                if let nextView = self.getNextViewInStack(usingIndex: index) {
                    let nextViewFrameMidXorY = self.isHorizontal ? nextView.frame.midX : nextView.frame.midY
                    if midXorY > nextViewFrameMidXorY {
                        
                        // Swap the two arranged subviews
                        UIView.animate(withDuration: 0.2, animations: {
                            self.insertArrangedSubview(nextView, at: index)
                            self.insertArrangedSubview(self.actualView, at: index + 1)
                        })
                        self.finalReorderFrame = self.actualView.frame
                        
                        if self.isHorizontal {
                            self.pointForReordering.x = self.actualView.frame.midX
                        } else {
                            self.pointForReordering.y = self.actualView.frame.midY
                        }
                    }
                }
                
            } else {
                // Dragging the view right
                let previousIndex = index - 1
                if let moveAllowed = self.reorderDelegate?.shouldAllowSubview?(self.actualView, toMoveToIndex: previousIndex) {
                    if (!moveAllowed) {
                        return
                    }
                }
                
                self.reorderDelegate?.didDragToReorder?(inForwardDirection: true, maxPoint: maxPoint, minPoint: minPoint)
                
                if let previousView = self.getPreviousViewInStack(usingIndex: index) {
                    let previousViewFrameMidXorY = self.isHorizontal ? previousView.frame.midX : previousView.frame.midY
                    if midXorY < previousViewFrameMidXorY {
                        
                        // Swap the two arranged subviews
                        UIView.animate(withDuration: 0.2, animations: {
                            self.insertArrangedSubview(previousView, at: index)
                            self.insertArrangedSubview(self.actualView, at: index - 1)
                        })
                        self.finalReorderFrame = self.actualView.frame
                        
                        if self.isHorizontal {
                            self.pointForReordering.x = self.actualView.frame.midX
                        } else {
                            self.pointForReordering.y = self.actualView.frame.midY
                        }
                    }
                }
            }
            
        } else if gr.state == .ended || gr.state == .failed {
            
            self.cleanupUpAfterReordering()
            self.reordering = false
            self.endIndex = self.indexOfArrangedSubview(self.actualView)
            if self.startIndex != self.endIndex {
                self.reorderDelegate?.didReorderArrangedSubviews?(self.arrangedSubviews)
            }
            self.reorderDelegate?.didEndReordering?()
            
        } else if gr.state == .cancelled {
            self.reorderDelegate?.didCancelReordering?()
        }
        
    }
    
    fileprivate func prepareForReordering() {
        
        self.clipsToBounds = self.clipsToBoundsWhileReordering
        
        // Configure the temporary view
        self.temporaryView = self.actualView.snapshotView(afterScreenUpdates: true)
        self.temporaryView.frame = self.actualView.frame
        self.finalReorderFrame = self.actualView.frame
        self.addSubview(self.temporaryView)
        
        self.actualView.alpha = 0
        
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
                self.clipsToBounds = !self.clipsToBoundsWhileReordering
        })
        
    }
    
    
    // MARK:- View Styling Methods
    // ---------------------------------------------------------------------------------------------
    
    fileprivate func styleViewsForReordering() {
        
        let scale = CGAffineTransform(scaleX: self.temporaryViewScale, y: self.temporaryViewScale)
        let translation = self.isHorizontal ? CGAffineTransform(translationX: 0, y: self.dragHintSpacing) : CGAffineTransform(translationX: self.dragHintSpacing, y: 0)
        self.temporaryView.transform = scale.concatenating(translation)
        self.temporaryView.alpha = self.temporaryViewAlpha
        self.temporaryView.layer.cornerRadius = self.cornerRadii
        self.temporaryView.clipsToBounds = true
        
        for subview in self.arrangedSubviews {
            if subview != self.actualView {
                subview.transform = CGAffineTransform(scaleX: self.otherViewsScale, y: self.otherViewsScale)
            }
        }
    }
    
    fileprivate func styleViewsForEndReordering() {
        
        // Return drag view to original appearance
        self.temporaryView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.temporaryView.frame = self.finalReorderFrame
        self.temporaryView.alpha = 1.0
        
        // Return other arranged subviews to original appearances
        for subview in self.arrangedSubviews {
            UIView.animate(withDuration: 0.3, animations: {
                subview.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        }
    }
    
    
    // MARK:- Stack View Helper Methods
    // ---------------------------------------------------------------------------------------------
    
    fileprivate func indexOfArrangedSubview(_ view: UIView) -> Int {
        for (index, subview) in self.arrangedSubviews.enumerated() {
            if view == subview {
                return index
            }
        }
        return 0
    }
    
    fileprivate func getPreviousViewInStack(usingIndex index: Int) -> UIView? {
        if index == 0 { return nil }
        return self.arrangedSubviews[index - 1]
    }
    
    fileprivate func getNextViewInStack(usingIndex index: Int) -> UIView? {
        if index == self.arrangedSubviews.count - 1 { return nil }
        return self.arrangedSubviews[index + 1]
    }
    
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !self.reordering
    }
    
}

fileprivate extension UIGestureRecognizer {
    func cancel() {
        isEnabled = false
        isEnabled = true
    }
}
