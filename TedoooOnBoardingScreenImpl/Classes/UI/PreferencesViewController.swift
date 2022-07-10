//
//  PreferencesViewController.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 07/07/2022.
//

import Foundation
import UIKit
import Kingfisher
import TedoooCombine
import TedoooStyling
import AlignedCollectionViewFlowLayout
import CreateShopFlowApi

class PreferenceCell: UICollectionViewCell {
    
    @IBOutlet weak var prefContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        layer.borderColor = UIColor(hex: "#6DC5A8").cgColor

    }
    
}

class PreferencesViewController: UIViewController {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnSkip: UIButton!
    
    private var bag = CombineBag()
    private lazy var viewModel = ActivityViewModel.get(navController: navigationController!)
    
    static func instantiate() -> UIViewController {
        return GPHelper.instantiateViewController(type: PreferencesViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        if let layout = collectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout {
            layout.horizontalAlignment = .left
        }
        
        Styling.styleJoyButton(view: btnNext)
        
        subscribe()
    }
    
    private func subscribe() {
        viewModel.categories.withPrevious().filter({!$0.current.isEmpty}).first().sink { [weak self] (previous, current) in
            guard let self = self else { return }
            if previous == nil {
                self.collectionView.reloadData()
            } else {
                self.collectionView.insertItems(at: (0..<current.count).map({IndexPath(row: $0, section: 0)}))
            }
        } => bag
        viewModel.loadingCategories.sink { [weak self] spinning in
            guard let self = self else { return }
            if spinning {
                self.spinner.startAnimating()
                self.collectionView.isHidden = true
            } else {
                self.spinner.stopAnimating()
                self.collectionView.isHidden = false
            }
        } => bag
        viewModel.selectedCategoriesCount.sink { [weak self] totalCategories in
            guard let self = self else { return }
            self.btnSkip.isHidden = totalCategories != 0
            if totalCategories == 0 {
                self.btnSkip.isHidden = false
                self.btnNext.backgroundColor = Styling.lightGrayColor
                self.btnNext.isEnabled = false
            } else {
                self.btnSkip.isHidden = true
                self.btnNext.backgroundColor = Styling.joyBlueColor
                self.btnNext.isEnabled = true
            }
        } => bag
    }
    
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextClicked() {
        viewModel.confirmCategories()
        viewModel.finishOnBoarding().sink { _ in
            self.viewModel.onboardingComplete.send(completion: .finished)
        } => self.bag
        if let navController = navigationController, viewModel.interests.value.contains("sell") {
            DIContainer.shared.resolve(CreateShopFlowApi.self).startFlow(in: navController, fromOnBoarding: true).sink { [weak self] result in
                switch result {
                case .finished: break
                case .failure(let err):
                    guard let self = self else { return }
                    switch err {
                    case .flowCancelled(let vc):
                        vc.dismiss(animated: true) {
                            self.viewModel.endSubject.send(AddShopResult(vc: self, id: "", action: .showHomePage))
                        }
                    }
                }
                self?.viewModel.endSubject.send(completion: .finished)
            } receiveValue: { [weak self] result in
                guard let self = self else { return }
                result.vc.dismiss(animated: true) {
                    self.viewModel.endSubject.send(AddShopResult(vc: self, id: result.id, action: result.action))
                    self.viewModel.endSubject.send(completion: .finished)
                }
                
            } => bag

            return
        }
        self.navigationController?.dismiss(animated: true)
    }
}

extension PreferencesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 110, height: 110)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedCategory(indexPath.row)
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! PreferenceCell
        let item = viewModel.categories.value[indexPath.row]
        let category = item.category
        if let image = category.baseImage {
            cell.mainImage.image = image
        } else if let url = URL(string: category.image) {
            cell.mainImage.kf.setImage(with: url)
        }
        cell.mainLabel.text = category.text
        if item.selected {
            cell.layer.borderWidth = 3
            cell.prefContainer.layer.shadowOpacity = 0
        } else {
            cell.layer.borderWidth = 0
            Styling.styleShadowView(cell.prefContainer, cornerRadius: 4, shadowOffset: .init(width: 0, height: 1), shadowRadius: 4, shadowOpacity: 0.25, shadowColor: UIColor.rgb(red: 176/255, green: 176/255, blue: 176/255))
        }
        cell.clipsToBounds = false

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.categories.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
