# SQReorderableStackView

[![CI Status](http://img.shields.io/travis/markedwardmurray/SQReorderableStackView.svg?style=flat)](https://travis-ci.org/markedwardmurray/SQReorderableStackView)
[![Version](https://img.shields.io/cocoapods/v/SQReorderableStackView.svg?style=flat)](http://cocoapods.org/pods/SQReorderableStackView)
[![License](https://img.shields.io/cocoapods/l/SQReorderableStackView.svg?style=flat)](http://cocoapods.org/pods/SQReorderableStackView)
[![Platform](https://img.shields.io/cocoapods/p/SQReorderableStackView.svg?style=flat)](http://cocoapods.org/pods/SQReorderableStackView)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* iOS 9.0 and later
* Swift 3 only

## Installation

SQReorderableStackView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SQReorderableStackView"
```

## Usage

`SQReorderableStackView` is a subclass of `UIStackView`. To use with Interface Builder, add a `UIStackView` nib and set its custom class to `SQReorderableStackView`. It does not require a `reorderDelegate` to be set.  
**NOTE:** Any subviews whose `userInteractionEnabled` property is set to `false` will not be able to be "picked up" by the user. 

### Public Properties

```swift
SQReorderableStackView

    /// Whether or not the subviews can be picked and reordered.
    public var reorderingEnabled = true

    /// The delegate for reordering.
    public var reorderDelegate: SQReorderableStackViewDelegate?

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
    public var longPressMinimumPressDuration = 0.2
    
    /// Determines whether or not the axis is horizontal.
    public var isHorizontal: Bool // readonly
    
    /// Determines whether or not the axis is vertical.
    public var isVertical: Bool // readonly
```

### Delegate Methods

Using a `reorderDelegate` allows both finer control of individual subviews' reordering and responding to changes made to the order of the subviews by the user.

```swift
SQReorderableStackViewDelegate

    /// called when a subview is "picked up" by the user
    @objc optional func stackViewDidBeginReordering(_ stackView: SQReorderableStackView)
    
    /// Whenever a user drags a subview for a reordering, the delegate is told whether the direction
    /// was forward (left/down) or backward (right/up), as well as what the max and min X or Y values are of the subview
    @objc optional func stackView(_ stackView: SQReorderableStackView, didDragToReorderInForwardDirection forward: Bool, maxPoint: CGPoint, minPoint: CGPoint)
    
    /// didReorderArrangedSubviews - called when reordering ends only if the selected subview's index changed during reordering
    @objc optional func stackView(_ stackView: SQReorderableStackView, didReorderArrangedSubviews arrangedSubviews: Array<UIView>)
    
    /// didEndReordering - called when reordering ends
    @objc optional func stackViewDidEndReordering(_ stackView: SQReorderableStackView)
    
    /// called when reordering is cancelled
    @objc optional func stackViewDidCancelReordering(_ stackView: SQReorderableStackView)
    
    /// Tells the ReorderableStackView whether or not the pressed subview may be picked up.
    @objc optional func stackView(_ stackView: SQReorderableStackView, canReorderSubview subview: UIView, atIndex index: Int) -> Bool
    
    /// Tells the ReorderableStackView whether or not the held subview can take the spot at which is being held.
    @objc optional func stackView(_ stackView: SQReorderableStackView, shouldAllowSubview subview: UIView, toMoveToIndex index: Int) -> Bool
```

For example, an individual subview can be disallowed from being reordered or moved. To keep the stackView's third subview (index 2) from being picked up or replaced:

```swift
    func stackView(_ stackView: SQReorderableStackView, canReorderSubview subview: UIView, atIndex index: Int) -> Bool {
        if index == 2 {
            return false
        } else {
            return true
        }
    }

    func stackView(_ stackView: SQReorderableStackView, shouldAllowSubview subview: UIView, toMoveToIndex index: Int) -> Bool {
        if index == 2 {
            return false
        } else {
            return true
        }
    }
```

Also, the delegate can respond to a completed reordering action, such as updating values based on the new order:

```swift
    func stackViewDidReorderArrangedSubviews(_ stackView: SQReorderableStackView) {
                var text = ""
        for label in stackView.arrangedSubviews as! [UILabel] {
            text.append(label.text!)
            text.append(" ")
        }
        
        self.label.text = text
    }
```
**NOTE:** `stackViewDidEndReordering(_:)` will be called each time the user interaction ends whether or not the subviews were reordered. `stackViewDidReorderArrangedSubviews(_:)` will only be called if the order of the subviews was changed.

## Author

markedwardmurray, markedwardmurray@gmail.com

`SQReorderableStackView` is adapted from `[APReorderableStackView](https://github.com/clayellis/APReorderableStackView/blob/master/ReorderStackView/APRedorderableStackView.swift) uploaded to GitHub by [Clay Ellis](https://github.com/clayellis)


## License

`SQReorderableStackView` is available under the MIT license. See the LICENSE file for more info.
