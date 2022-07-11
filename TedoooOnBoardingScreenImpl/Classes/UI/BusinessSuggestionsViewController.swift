//
//  BusinessSuggestionsViewController.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 07/07/2022.
//

import Foundation
import Combine
import TedoooCombine
import TedoooStyling
import TedoooFullScreenHud
import TedoooSkeletonView
import TedoooOnBoardingApi
import CreateShopFlowApi

class BusinessSuggestionCell: UITableViewCell {
 
    @IBOutlet weak var radioButton: StrokedRadioButton!
    @IBOutlet weak var lblShopName: UILabel!
    @IBOutlet weak var shopImage: UIImageView!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblCategory: UILabel!
    
    @IBOutlet weak var imgStar5: UIImageView!
    @IBOutlet weak var imgStar4: UIImageView!
    @IBOutlet weak var imgStar3: UIImageView!
    @IBOutlet weak var imgStar2: UIImageView!
    @IBOutlet weak var imgStar1: UIImageView!
    
    
    var bag = CombineBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        shopImage.kf.indicatorType = .activity
        radioButton.setCircleColor(.black)
        lblShopName.linesCornerRadius = 8
        lblDescription.linesCornerRadius = 8
        lblCategory.linesCornerRadius = 8
        
        shopImage.skeletonCornerRadius = 37
        lblDescription.skeletonTextNumberOfLines = 1
        lblDescription.skeletonLineSpacing = 4
        
        imgStar1.skeletonCornerRadius = 4
        imgStar2.skeletonCornerRadius = 4
        imgStar3.skeletonCornerRadius = 4
        imgStar4.skeletonCornerRadius = 4
        imgStar5.skeletonCornerRadius = 4
    }
    
    
    func setSkeleton(_ skeleton: Bool) {
        if skeleton {
            radioButton.isHidden = true
            lblShopName.showAnimatedSkeleton()
            lblDescription.showAnimatedSkeleton()
            shopImage.showAnimatedSkeleton()
            lblCategory.showAnimatedSkeleton()
            
            imgStar1.showAnimatedSkeleton()
            imgStar2.showAnimatedSkeleton()
            imgStar3.showAnimatedSkeleton()
            imgStar4.showAnimatedSkeleton()
            imgStar5.showAnimatedSkeleton()
        } else {
            radioButton.isHidden = false
            lblDescription.hideSkeleton()
            shopImage.hideSkeleton()
            lblCategory.hideSkeleton()
            
            imgStar1.hideSkeleton()
            imgStar2.hideSkeleton()
            imgStar3.hideSkeleton()
            imgStar4.hideSkeleton()
            imgStar5.hideSkeleton()
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = CombineBag()
    }
    
}

class BusinessSuggestionViewController: UIViewController {
    
    @IBOutlet weak var tableSuggestions: UITableView!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnSkip: UIButton!
    
    private var bag = CombineBag()
    private lazy var viewModel = ActivityViewModel.get(navController: navigationController!)
    
    static func instantiate() -> UIViewController {
        return GPHelper.instantiateViewController(type: BusinessSuggestionViewController.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableSuggestions.delegate = self
        tableSuggestions.dataSource = self
        
        Styling.styleJoyButton(view: btnNext)
        
        subscribe()
    }
    
    private func subscribe() {

        viewModel.businessSuggestions.combineLatest(viewModel.loadingBusinesses).map { (suggestions, loading) -> [BusinessSuggestion] in
            if loading {
                return [
                    BusinessSuggestion(id: "loading1", name: "", rating: 0, totalReviews: 0, categories: [], description: "", image: nil),
                    BusinessSuggestion(id: "loading2", name: "", rating: 0, totalReviews: 0, categories: [], description: "", image: nil),
                    BusinessSuggestion(id: "loading3", name: "", rating: 0, totalReviews: 0, categories: [], description: "", image: nil)
                ]
            }
            return suggestions.map({$0.suggestion})
        }.removeDuplicates().withPrevious().sink { [weak self] (previous, current) in
            guard let self = self else { return }
            if let previous = previous {
                self.tableSuggestions.performBatchUpdates {
                    if previous.count < current.count {
                        self.tableSuggestions.reloadRows(at: (0..<previous.count).map({IndexPath(row: $0, section: 0)}), with: .automatic)
                        self.tableSuggestions.insertRows(at: (previous.count..<current.count).map({IndexPath(row: $0, section: 0)}), with: .automatic)
                    } else if previous.count == current.count {
                        self.tableSuggestions.reloadRows(at: (0..<previous.count).map({IndexPath(row: $0, section: 0)}), with: .automatic)
                    } else {
                        self.tableSuggestions.reloadRows(at: (0..<current.count).map({IndexPath(row: $0, section: 0)}), with: .automatic)
                        self.tableSuggestions.deleteRows(at: (current.count..<previous.count).map({IndexPath(row: $0, section: 0)}), with: .automatic)
                        
                    }
                } completion: { _ in
                }
            } else {
                self.tableSuggestions.reloadData()
            }
        } => bag
        viewModel.selectionsBusiness.sink { [weak self] selections in
            guard let self = self else { return }
            self.btnSkip.isHidden = selections.count != 0
            switch selections.count {
            case 0:
                self.btnNext.setTitle(NSLocalizedString("Follow Shops", comment: ""), for: .normal)
                self.btnNext.backgroundColor = Styling.lightGrayColor
                self.btnNext.isEnabled = false
            case 1:
                self.btnNext.setTitle(String(format: NSLocalizedString("Follow %@", comment: ""), selections.first!), for: .normal)
                self.btnNext.backgroundColor = Styling.joyBlueColor
                self.btnNext.isEnabled = true
            default:
                self.btnNext.setTitle(String(format: NSLocalizedString("Follow Shops (%d)", comment: ""), selections.count), for: .normal)
                self.btnNext.backgroundColor = Styling.joyBlueColor
                self.btnNext.isEnabled = true
            }
        } => bag
    }
    
    @IBAction func backClicked() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextClicked() {
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

extension BusinessSuggestionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.loadingBusinesses.value ? 3 : viewModel.businessSuggestions.value.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedBusinessSuggestion(at: indexPath.row)
    }
    
    private static func fixStars(starImageView: UIImageView, starCount: Int, realCount: CGFloat) {
        let sc = CGFloat(starCount)
        if realCount >= sc {
            starImageView.image = UIImage(named: "fullstar")
        } else if realCount > sc - 1 {
            starImageView.image = UIImage(named: "halfstar")
        } else {
            starImageView.image = UIImage(named: "emptystar")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! BusinessSuggestionCell
        if viewModel.loadingBusinesses.value {
            cell.setSkeleton(true)
            return cell
        }
        cell.setSkeleton(false)
        let item = viewModel.businessSuggestions.value[indexPath.row]
        let businessItem = item.suggestion
        if let image = businessItem.image, let url = URL(string: image) {
            cell.shopImage.kf.setImage(with: url)
        } else {
            cell.shopImage.image = UIImage(named: "group_placeholder")
        }
        cell.lblShopName.text = businessItem.name
        cell.lblDescription.text = businessItem.description
        if businessItem.categories.isEmpty {
            cell.lblCategory.isHidden = true
        } else {
            cell.lblCategory.isHidden = false
            if businessItem.categories.count <= 2 {
                cell.lblCategory.text = businessItem.categories.joined(separator: ", ")
            } else {
                cell.lblCategory.text = businessItem.categories[0..<2].joined(separator: ", ")
            }
        }
        BusinessSuggestionViewController.fixStars(starImageView: cell.imgStar1, starCount: 1, realCount: businessItem.rating)
        BusinessSuggestionViewController.fixStars(starImageView: cell.imgStar2, starCount: 2, realCount: businessItem.rating)
        BusinessSuggestionViewController.fixStars(starImageView: cell.imgStar3, starCount: 3, realCount: businessItem.rating)
        BusinessSuggestionViewController.fixStars(starImageView: cell.imgStar4, starCount: 4, realCount: businessItem.rating)
        BusinessSuggestionViewController.fixStars(starImageView: cell.imgStar5, starCount: 5, realCount: businessItem.rating)

        cell.selectionStyle = .none
        
        item.selected.sink { [weak cell] selected in
            cell?.radioButton.setChecked(selected, animated: true)
        } => cell.bag
        
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
}
