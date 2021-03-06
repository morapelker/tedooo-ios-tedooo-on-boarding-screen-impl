//
//  ActivityViewModel.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 07/07/2022.
//

import Foundation
import Combine
import TedoooOnBoardingApi
import TedoooCombine
import TedoooCategoriesApi
import CreateShopFlowApi
import TedoooAnalytics


class SelectedCategory {
    
    let category: TedoooCategoriesApi.Category
    var selected: Bool
    
    public init(category: TedoooCategoriesApi.Category, selected: Bool) {
        self.category = category
        self.selected = selected
    }
}

class BusinessSuggestionWithSelection {
    
    let suggestion: BusinessSuggestion
    let selected: CurrentValueSubject<Bool, Never>
    
    public init(suggestion: BusinessSuggestion, selected: Bool) {
        self.suggestion = suggestion
        self.selected = CurrentValueSubject(selected)
    }
    
}

class GroupSuggestionWithSelection {
    
    let suggestion: GroupSuggestion
    let selected: CurrentValueSubject<Bool, Never>
    
    public init(suggestion: GroupSuggestion, selected: Bool) {
        self.suggestion = suggestion
        self.selected = CurrentValueSubject(selected)
    }
    
}

class ActivityViewModel {
    
    struct ConfirmedPreference {
        let interests: [String]
        let categories: [TedoooCategoriesApi.Category]
    }
    
    private static let VM_KEY = "ONBOARDING_VM_KEY"
    
    static func get(navController: UIViewController) -> ActivityViewModel {
        if let vm = navController.view.layer.value(forKey: VM_KEY) as? ActivityViewModel {
            return vm
        }
        let viewModel = ActivityViewModel()
        navController.view.layer.setValue(viewModel, forKey: VM_KEY)
        return viewModel
    }
    
    private var api: TedoooOnBoardingApi
    private var bag = CombineBag()
    
    let endSubject = PassthroughSubject<AddShopResult, Never>()
    let onboardingComplete = PassthroughSubject<Any?, Never>()
    
    let businessSuggestions = CurrentValueSubject<[BusinessSuggestionWithSelection], Never>([])
    let loadingBusinesses = CurrentValueSubject<Bool, Never>(true)
    let selectionsBusiness = CurrentValueSubject<[String], Never>([])
        
    let groupSuggestions = CurrentValueSubject<[GroupSuggestionWithSelection], Never>([])
    let loadingGroups = CurrentValueSubject<Bool, Never>(true)
    let selectionGroups = CurrentValueSubject<[String], Never>([])
    
    let sellItems = CurrentValueSubject<Bool, Never>(false)
    let buyItems = CurrentValueSubject<Bool, Never>(false)
    let discoverCrafts = CurrentValueSubject<Bool, Never>(false)
    let upcycleRepurpose = CurrentValueSubject<Bool, Never>(false)
    let gardeningTips = CurrentValueSubject<Bool, Never>(false)
    let other = CurrentValueSubject<Bool, Never>(false)
    
    let interests = CurrentValueSubject<[String], Never>([])
    
    enum HasSuggestionsState {
        case hasSuggestions
        case noSuggestions
        case loading
    }
    
    let hasSuggestions = CurrentValueSubject<HasSuggestionsState, Never>(.loading)
    
    
    @Inject private var categoriesProvider: CategoriesProvider
    
    let categories = CurrentValueSubject<[SelectedCategory], Never>([])
    let loadingCategories = CurrentValueSubject<Bool, Never>(false)
    private let confirmedCategories = CurrentValueSubject<ConfirmedPreference, Never>(ConfirmedPreference(interests: [], categories: []))
    let selectedCategoriesCount = CurrentValueSubject<Int, Never>(0)
    
    func selectedCategory(_ index: Int) {
        let category = categories.value[index]
        category.selected = !category.selected
        selectedCategoriesCount.value = categories.value.filter({$0.selected}).count
    }
    
    func clearCategories() {
        categories.value.forEach { category in
            category.selected = false
        }
        selectedCategoriesCount.value = 0
        confirmCategories()
    }
    
    private func selectionChanged(_ selection: String, on: Bool) {
        if on {
            if !interests.value.contains(selection) {
                interests.value = interests.value + [selection]
            }
        } else {
            interests.value = interests.value.filter({$0 != selection})
        }
    }
    
    private let logger: TedoooAnalytics
    
    func logEvent(event: String) {
        logger.logEvent(event, payload: nil)
    }
    
    private init() {
        logger = DIContainer.shared.resolve(TedoooAnalytics.self)
        api = DIContainer.shared.resolve(TedoooOnBoardingApi.self)
                
        api.hasSuggestions().sink { [weak self] hasSuggestions in
            guard let self = self else { return }
            self.hasSuggestions.send(hasSuggestions ? .hasSuggestions : .noSuggestions)
            if hasSuggestions {
                self.logEvent(event: "onboarding_has_suggestions")
            } else {
                self.logEvent(event: "onboarding_no_suggestions")
            }
            self.hasSuggestions.send(completion: .finished)
        } => bag
        
        let cats = categoriesProvider.provideCategories()
        if !cats.instant {
            loadingCategories.value = true
        }
        cats.subject.sink { [weak self] categories in
            guard let self = self else { return }
            self.categories.value = categories.map({SelectedCategory(category: $0, selected: false)})
            self.loadingCategories.value = false
        } => bag
        
        sellItems.dropFirst().sink { [weak self] sell in
            self?.selectionChanged("sell", on: sell)
        } => bag
        buyItems.dropFirst().sink { [weak self] sell in
            self?.selectionChanged("buy", on: sell)
        } => bag
        discoverCrafts.dropFirst().sink { [weak self] sell in
            self?.selectionChanged("discover", on: sell)
        } => bag
        upcycleRepurpose.dropFirst().sink { [weak self] sell in
            self?.selectionChanged("upcycle", on: sell)
        } => bag
        gardeningTips.dropFirst().sink { [weak self] sell in
            self?.selectionChanged("gardening", on: sell)
        } => bag
        other.dropFirst().sink { [weak self] sell in
            self?.selectionChanged("other", on: sell)
        } => bag
        
        
        self.hasSuggestions.combineLatest(confirmedCategories.dropFirst()).filter({$0.0 == .hasSuggestions}).map({$0.1}).withPrevious().map { (previous, current) -> Bool in
            if let previous = previous {
                if previous.categories != current.categories {
                    return true
                }
                if previous.interests.count != current.interests.count {
                    return true
                }
                if previous.interests.contains(where: { it in
                    !current.interests.contains(it)
                }) {
                    return true
                }
            } else {
                return true
            }
            return false
        }.filter({$0}).sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.groupSuggestions.value = []
            self.businessSuggestions.value = []
            self.loadingGroups.value = true
            self.loadingBusinesses.value = true
            let suggestions = self.api.getGroupSuggestions(interests: self.interests.value)
            suggestions.sink { [weak self] suggestions in
                guard let self = self else { return }
                self.groupSuggestions.value = suggestions.map({GroupSuggestionWithSelection(suggestion: $0, selected: true)})
                self.loadingGroups.value = false
                self.selectionGroups.value = self.groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
            } => self.bag
            let businessSuggestions = self.api.getBusinessSuggestions(interests: self.interests.value, limit: 5)
            businessSuggestions.sink { [weak self] suggestions in
                guard let self = self else { return }
                self.businessSuggestions.value = suggestions.map({BusinessSuggestionWithSelection(suggestion: $0, selected: true)})
                self.loadingBusinesses.value = false
                self.selectionsBusiness.value = self.businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
            } => self.bag
            
        }) => bag
        
    }
    
    func finishOnBoarding() -> AnyPublisher<Any?, Never> {
        /*logEvent("onboarding_finished", bundleOf(
            "interestCount" to interests.value.size,
            "join_groups" to groupSelections.value.size,
            "follow_businesses" to businessSelections.value.size
            
        ))*/
        let selectedGroups = groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.id})
        let selectedBusiness = businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.id})
        logger.logEvent("onboarding_finished", payload: [
            "interestCount": confirmedCategories.value.interests.count,
            "join_groups": selectedGroups.count,
            "follow_businesses": selectedBusiness.count
        ])
        return api.finishOnBoarding(request: FinishOnBoardingRequest(interests: confirmedCategories.value.interests, preferences: confirmedCategories.value
            .categories.map({$0.id}), groups: selectedGroups, businesses: selectedBusiness))
    }
    
    func confirmCategories() {
        confirmedCategories.value = ConfirmedPreference(interests: interests.value, categories: categories.value.filter({$0.selected}).map({$0.category}))
    }
    
    func selectedGroupSuggestion(at index: Int) {
        guard groupSuggestions.value.count > index else { return }
        let item = groupSuggestions.value[index]
        item.selected.value = !item.selected.value
        selectionGroups.value = groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
    }
    
    func selectedBusinessSuggestion(at index: Int) {
        guard businessSuggestions.value.count > index else { return }
        let item = businessSuggestions.value[index]
        item.selected.value = !item.selected.value
        selectionsBusiness.value = businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
    }
    
}
