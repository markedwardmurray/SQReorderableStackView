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
        
        horizontalStackView.reorderDelegate = self
        verticalStackView.reorderDelegate = self
        
        updateLabelText()
    }
    
    func stackView(_ stackView: SQReorderableStackView, canReorderSubview subview: UIView, atIndex index: Int) -> Bool {
        if stackView == horizontalStackView {
            if index == 2 {
                return false
            }
        }
        return true
    }

    func stackView(_ stackView: SQReorderableStackView, shouldAllowSubview subview: UIView, toMoveToIndex index: Int) -> Bool {
        if stackView == horizontalStackView {
            if index == 2 {
                return false
            }
        }
        return true
    }

    func stackViewDidReorderArrangedSubviews(_ stackView: SQReorderableStackView) {
        if stackView == verticalStackView {
            updateLabelText()
        }
    }
    
    func updateLabelText() {
        var text = ""
        for label in verticalStackView.arrangedSubviews as! [UILabel] {
            text.append(label.text!)
            text.append(" ")
        }
        
        label.text = text
    }
}

