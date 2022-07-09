//
//  InitialViewController.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 06/07/2022.
//

import Foundation
import UIKit
import TedoooStyling
import TedoooCombine
import Combine

class InitialViewController: UIViewController {
    
    static func instantiate() -> UIViewController {
        let vc = GPHelper.instantiateViewController(type: InitialViewController.self)
        return vc
    }
    
    private lazy var viewModel = ActivityViewModel.get(navController: self.navigationController!)
    private var bag = CombineBag()
    
    @IBOutlet weak var btnSkip: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnSell: UIView!
    @IBOutlet weak var btnBuyItems: UIView!
    @IBOutlet weak var btnDiscoverCrafts: UIView!
    @IBOutlet weak var btnUpcycleDiy: UIView!
    @IBOutlet weak var btnGardeningTips: UIView!
    @IBOutlet weak var btnOther: UIView!
    
    @IBOutlet weak var checkSell: StrokedRadioButton!
    @IBOutlet weak var checkBuyItems: StrokedRadioButton!
    @IBOutlet weak var checkDiscoverCrafts: StrokedRadioButton!
    @IBOutlet weak var checkUpcycleDiy: StrokedRadioButton!
    @IBOutlet weak var checkGardening: StrokedRadioButton!
    @IBOutlet weak var checkOther: StrokedRadioButton!
    
    @IBOutlet weak var btnClose: UIView!
    
    private static func styleButton(_ view: UIView) {
        view.layer.cornerRadius = 8
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkSell.backgroundColor = .clear
        checkBuyItems.backgroundColor = .clear
        checkDiscoverCrafts.backgroundColor = .clear
        checkUpcycleDiy.backgroundColor = .clear
        checkGardening.backgroundColor = .clear
        checkOther.backgroundColor = .clear
        
        InitialViewController.styleButton(btnSell)
        InitialViewController.styleButton(btnBuyItems)
        InitialViewController.styleButton(btnDiscoverCrafts)
        InitialViewController.styleButton(btnUpcycleDiy)
        InitialViewController.styleButton(btnGardeningTips)
        InitialViewController.styleButton(btnOther)
        
        checkSell.setBorder(.init(hex: "#FACCC4"))
        checkBuyItems.setBorder(.init(hex: "#C5C5F2"))
        checkDiscoverCrafts.setBorder(.init(hex: "#B5DCE2"))
        checkUpcycleDiy.setBorder(.init(hex: "#F4CEBB"))
        checkGardening.setBorder(.init(hex: "#B6DB99"))
        checkOther.setBorder(.init(hex: "#E3C18D"))
        
        Styling.styleJoyButton(view: btnNext)
        
        btnClose.addGestureRecognizer(target: self, selector: #selector(closeClicked))
        
        btnSell.addGestureRecognizer(target: self, selector: #selector(selectedSell))
        btnBuyItems.addGestureRecognizer(target: self, selector: #selector(selectedBuy))
        btnDiscoverCrafts.addGestureRecognizer(target: self, selector: #selector(selectedDiscover))
        btnUpcycleDiy.addGestureRecognizer(target: self, selector: #selector(selectedUpcycle))
        btnGardeningTips.addGestureRecognizer(target: self, selector: #selector(selecedGardening))
        btnOther.addGestureRecognizer(target: self, selector: #selector(selectedOther))
        
        navigationItem.backButtonTitle = NSLocalizedString("Interests", comment: "")
        
        subscribe()
    }
    
    @IBAction func nextClicked() {
        viewModel.confirmCategories()
        let vc = GroupSuggestionsViewController.instantiate()
        navigationController?.pushViewController(vc, animated: true)
        return
    }
    
    @objc private func selectedBuy() {
        viewModel.buyItems.value = !viewModel.buyItems.value
    }
    
    @objc private func selectedSell() {
        viewModel.sellItems.value = !viewModel.sellItems.value
    }
    
    @objc private func selectedDiscover() {
        viewModel.discoverCrafts.value = !viewModel.discoverCrafts.value
    }
    
    @objc private func selectedUpcycle() {
        viewModel.upcycleRepurpose.value = !viewModel.upcycleRepurpose.value
    }
    
    @objc private func selecedGardening() {
        viewModel.gardeningTips.value = !viewModel.gardeningTips.value
    }
    
    @objc private func selectedOther() {
        viewModel.other.value = !viewModel.other.value
    }
    
    private func subscribe() {
        viewModel.interests.map({$0.count}).sink { [weak self] total in
            guard let self = self else { return }
            self.btnSkip.isHidden = total != 0
            if total == 0 {
                self.btnNext.isEnabled = false
                self.btnNext.backgroundColor = Styling.lightGrayColor
                self.btnNext.setTitle(NSLocalizedString("Next", comment: ""), for: .normal)
            } else {
                self.btnNext.isEnabled = true
                self.btnNext.backgroundColor = Styling.joyBlueColor
                self.btnNext.setTitle(String(format: NSLocalizedString("Next (%d)", comment: ""), total), for: .normal)
            }
        } => bag
        viewModel.buyItems.sink { [weak self] buyItems in
            guard let self = self else { return }
            self.checkBuyItems.setChecked(buyItems, animated: true)
        } => bag
        viewModel.sellItems.sink { [weak self] sellItems in
            guard let self = self else { return }
            self.checkSell.setChecked(sellItems, animated: true)
        } => bag
        viewModel.discoverCrafts.sink { [weak self] sellItems in
            guard let self = self else { return }
            self.checkDiscoverCrafts.setChecked(sellItems, animated: true)
        } => bag
        viewModel.gardeningTips.sink { [weak self] sellItems in
            guard let self = self else { return }
            self.checkGardening.setChecked(sellItems, animated: true)
        } => bag
        viewModel.other.sink { [weak self] sellItems in
            guard let self = self else { return }
            self.checkOther.setChecked(sellItems, animated: true)
        } => bag
        viewModel.upcycleRepurpose.sink { [weak self] sellItems in
            guard let self = self else { return }
            self.checkUpcycleDiy.setChecked(sellItems, animated: true)
        } => bag
    }
    
    @objc private func closeClicked() {
        self.dismiss(animated: true)
    }
    
    
    
}
