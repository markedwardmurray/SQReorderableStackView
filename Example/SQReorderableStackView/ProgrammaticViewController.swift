//
//  ProgrammaticViewController.swift
//  SQReorderableStackView_Example
//
//  Created by Mark Murray on 6/4/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import SQReorderableStackView

class ProgrammaticViewController: UIViewController, SQReorderableStackViewDelegate {
    let horizontalStackView: SQReorderableStackView = {
        let stackView = SQReorderableStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.autoresizesSubviews = true
        
        return stackView
    }()
    
    let verticalStackView: SQReorderableStackView = {
        let stackView = SQReorderableStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.autoresizesSubviews = true
        
        return stackView
    }()
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        horizontalStackView.reorderDelegate = self
        verticalStackView.reorderDelegate = self
        
        view.addSubview(horizontalStackView)
        view.addSubview(verticalStackView)
        view.addSubview(label)
        
        setupConstraints()
        addHorizontalLabels()
        addVerticalLabels()
        
        updateLabelText()
    }
    
    private func setupConstraints() {
        horizontalStackView.heightAnchor.constraint(equalTo: horizontalStackView.widthAnchor, multiplier: 1.0/3.0).isActive = true
        horizontalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        horizontalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        horizontalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        
        verticalStackView.topAnchor.constraint(equalTo: horizontalStackView.bottomAnchor, constant: 80).isActive = true
        verticalStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        
        label.heightAnchor.constraint(equalToConstant: 140).isActive = true
        label.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 80).isActive = true
        label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -25).isActive = true
    }
    
    private func addHorizontalLabels() {
        let labelOne = UILabel()
        labelOne.text = "1"
        labelOne.textAlignment = .center
        labelOne.backgroundColor = .cyan
        labelOne.widthAnchor.constraint(equalTo: labelOne.heightAnchor, multiplier: 1).isActive = true
        labelOne.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(labelOne)
        
        let labelTwo = UILabel()
        labelTwo.text = "2"
        labelTwo.textAlignment = .center
        labelTwo.backgroundColor = .lightGray
        labelTwo.widthAnchor.constraint(equalTo: labelTwo.heightAnchor, multiplier: 1).isActive = true
        labelTwo.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(labelTwo)
        
        let labelX = UILabel()
        labelX.text = "X"
        labelX.textAlignment = .center
        labelX.backgroundColor = .red
        labelX.widthAnchor.constraint(equalTo: labelX.heightAnchor, multiplier: 1).isActive = true
        labelX.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(labelX)
    }
    
    private func addVerticalLabels() {
        let lorem = UILabel()
        lorem.text = "Lorem"
        lorem.textAlignment = .center
        lorem.backgroundColor = .cyan
        lorem.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(lorem)
        
        let ipsum = UILabel()
        ipsum.text = "ipsum"
        ipsum.textAlignment = .center
        ipsum.backgroundColor = .cyan
        ipsum.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(ipsum)
        
        let dolor = UILabel()
        dolor.text = "dolor"
        dolor.textAlignment = .center
        dolor.backgroundColor = .cyan
        dolor.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(dolor)
        
        let sit = UILabel()
        sit.text = "sit"
        sit.textAlignment = .center
        sit.backgroundColor = .cyan
        sit.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(sit)
        
        let amet = UILabel()
        amet.text = "amet"
        amet.textAlignment = .center
        amet.backgroundColor = .cyan
        amet.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(amet)
    }
    
    func updateLabelText() {
        var text = ""
        for label in verticalStackView.arrangedSubviews as! [UILabel] {
            text.append(label.text!)
            text.append(" ")
        }
        
        label.text = text
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
}
