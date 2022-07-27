//
//  GroupSuggestionsViewController.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 07/07/2022.
//

import Foundation
import Combine
import TedoooCombine
import TedoooStyling
import TedoooSkeletonView
import TedoooOnBoardingApi

class GroupSuggestionCell: UITableViewCell {
 
    @IBOutlet weak var radioButton: StrokedRadioButton!
    @IBOutlet weak var lblGroupName: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblParticipants: UILabel!
    
    var bag = CombineBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        groupImage.kf.indicatorType = .activity
        radioButton.setCircleColor(.black)
        lblGroupName.linesCornerRadius = 8
        lblDescription.linesCornerRadius = 8
        lblParticipants.linesCornerRadius = 8
        
        lblDescription.skeletonTextNumberOfLines = 2
        lblDescription.skeletonLineSpacing = 4
        
        groupImage.skeletonCornerRadius = 37
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = CombineBag()
    }
    
    func setSkeleton(_ skeleton: Bool) {
        if skeleton {
            radioButton.isHidden = true
            lblGroupName.showAnimatedSkeleton()
            lblDescription.showAnimatedSkeleton()
            lblParticipants.showAnimatedSkeleton()
            groupImage.showAnimatedSkeleton()
        } else {
            radioButton.isHidden = false
            lblGroupName.hideSkeleton()
            lblDescription.hideSkeleton()
            lblParticipants.hideSkeleton()
            groupImage.hideSkeleton()
        }
        
    }
    
}

class GroupSuggestionsViewController: UIViewController {
    
    @IBOutlet weak var tableSuggestions: UITableView!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var btnSkip: UIButton!

    private var bag = CombineBag()
    
    static func instantiate() -> UIViewController {
        return GPHelper.instantiateViewController(type: GroupSuggestionsViewController.self)
    }
    
    private lazy var viewModel = ActivityViewModel.get(navController: self.navigationController!)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.logEvent(event: "onboarding_step_group")
        tableSuggestions.delegate = self
        tableSuggestions.dataSource = self
        
        Styling.styleJoyButton(view: btnNext)
        
        subscribe()
    }
    
    private func subscribe() {
        viewModel.groupSuggestions.combineLatest(viewModel.loadingGroups).map { (suggestions, loading) -> [GroupSuggestion] in
            if loading {
                return [
                    GroupSuggestion(id: "loading1", name: "", participants: 0, description: "", image: nil),
                    GroupSuggestion(id: "loading2", name: "", participants: 0, description: "", image: nil),
                    GroupSuggestion(id: "loading3", name: "", participants: 0, description: "", image: nil)
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
        
        viewModel.selectionGroups.sink { [weak self] selections in
            guard let self = self else { return }
            self.btnSkip.isHidden = selections.count != 0
            switch selections.count {
            case 0:
                self.btnNext.setTitle(NSLocalizedString("Join Groups", comment: ""), for: .normal)
                self.btnNext.backgroundColor = Styling.lightGrayColor
                self.btnNext.isEnabled = false
            case 1:
                self.btnNext.setTitle(String(format: NSLocalizedString("Join %@", comment: ""), selections.first!), for: .normal)
                self.btnNext.backgroundColor = Styling.joyBlueColor
                self.btnNext.isEnabled = true
            default:
                self.btnNext.setTitle(String(format: NSLocalizedString("Join Groups (%d)", comment: ""), selections.count), for: .normal)
                self.btnNext.backgroundColor = Styling.joyBlueColor
                self.btnNext.isEnabled = true
            }
        } => bag
    }
    
    @IBAction func backClicked() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextClicked() {
        let vc = BusinessSuggestionViewController.instantiate()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func skipClicked() {
        let vc = BusinessSuggestionViewController.instantiate()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension GroupSuggestionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.loadingGroups.value ? 3 : viewModel.groupSuggestions.value.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectedGroupSuggestion(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! GroupSuggestionCell
        if viewModel.loadingGroups.value {
            cell.setSkeleton(true)
            cell.selectionStyle = .none
            return cell
        }
        cell.setSkeleton(false)
        let item = viewModel.groupSuggestions.value[indexPath.row]
        let groupItem = item.suggestion
        if let image = groupItem.image, let url = URL(string: image) {
            cell.groupImage.kf.setImage(with: url)
        } else {
            cell.groupImage.image = UIImage(named: "group_placeholder")
        }
        cell.lblGroupName.text = groupItem.name
        cell.lblDescription.text = groupItem.description
        cell.lblParticipants.text = String(format: NSLocalizedString("%@ members", comment: ""), GPHelper.participantsToString(participants: groupItem.participants))
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
