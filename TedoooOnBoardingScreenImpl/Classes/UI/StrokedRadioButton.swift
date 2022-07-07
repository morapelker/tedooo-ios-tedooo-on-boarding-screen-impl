//
//  StrokedRadioButton.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 06/07/2022.
//

import Foundation
import Combine

class StrokedRadioButton: UIView {
    
    @IBOutlet weak var checkedCircle: UIView!
    @IBOutlet weak var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        Bundle(for: StrokedRadioButton.self).loadNibNamed("StrokedRadioButton", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.layoutIfNeeded()
        checkedCircle.layer.cornerRadius = checkedCircle.frame.width / 2
        checkedCircle.alpha = 0.0
        contentView.layer.cornerRadius = contentView.frame.width / 2
        contentView.layer.borderWidth = 2
    }
    
    func setBorder(_ borderColor: UIColor) {
        contentView.layer.borderColor = borderColor.cgColor
    }
    
    func setCircleColor(_ color: UIColor) {
        checkedCircle.backgroundColor = color
    }
    
    func setChecked(_ on: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.checkedCircle.alpha = on ? 1.0 : 0.0
            }
        } else {
            self.checkedCircle.alpha = on ? 1.0 : 0.0
        }
    }
}
