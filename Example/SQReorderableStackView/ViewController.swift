//
//  ViewController.swift
//  SQReorderableStackView
//
//  Created by markedwardmurray on 12/09/2016.
//  Copyright (c) 2016 markedwardmurray. All rights reserved.
//

import UIKit
import SQReorderableStackView

class ViewController: UIViewController, SQReorderableStackViewDelegate {

    @IBOutlet var horizontalStackView: SQReorderableStackView!
    @IBOutlet var verticalStackView: SQReorderableStackView!
    @IBOutlet var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.horizontalStackView.reorderDelegate = self
        self.verticalStackView.reorderDelegate = self
        
        self.updateLabelText()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func stackView(stackView: SQReorderableStackView, canReorderSubview subview: UIView, atIndex index: Int) -> Bool {
        if (stackView == self.horizontalStackView) {
            if index == 2 {
                return false
            }
        }
        return true
    }

    func stackView(stackView: SQReorderableStackView, shouldAllowSubview subview: UIView, toMoveToIndex index: Int) -> Bool {
        if (stackView == self.horizontalStackView) {
            if index == 2 {
                return false
            }
        }
        return true
    }

    func stackView(stackView: SQReorderableStackView, didReorderArrangedSubviews arrangedSubviews: Array<UIView>) {
        if stackView == self.verticalStackView {
            self.updateLabelText()
        }
    }
    
    func updateLabelText() {
        var text = ""
        for label in self.verticalStackView.arrangedSubviews as! [UILabel] {
            text.append(label.text!)
            text.append(" ")
        }
        
        self.label.text = text
    }
}

