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
    
    private init() {
        api = DIContainer.shared.resolve(TedoooOnBoardingApi.self)
        
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
        
        
        confirmedCategories.withPrevious().dropFirst().map { (previous, current) -> Bool in
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
            let groupSelections = Set(self.groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.id}))
            let businessSelections = Set(self.businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.id}))
            self.groupSuggestions.value = []
            self.businessSuggestions.value = []
            self.loadingGroups.value = true
            self.loadingBusinesses.value = true
            let suggestions = self.api.getGroupSuggestions(interests: self.interests.value)
            suggestions.sink { [weak self] suggestions in
                guard let self = self else { return }
                self.groupSuggestions.value = suggestions.map({GroupSuggestionWithSelection(suggestion: $0, selected: groupSelections.contains($0.id))})
                self.loadingGroups.value = false
                self.selectionGroups.value = self.groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
            } => self.bag
            let businessSuggestions = self.api.getBusinessSuggestions(interests: self.interests.value)
            businessSuggestions.sink { [weak self] suggestions in
                guard let self = self else { return }
                self.businessSuggestions.value = suggestions.map({BusinessSuggestionWithSelection(suggestion: $0, selected: businessSelections.contains($0.id))})
                self.loadingBusinesses.value = false
                self.selectionsBusiness.value = self.businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
            } => self.bag
            
        }) => bag
        
    }
    
    func finishOnBoarding() -> AnyPublisher<Any?, Never> {
        return api.finishOnBoarding(request: FinishOnBoardingRequest(interests: confirmedCategories.value.interests, preferences: confirmedCategories.value
            .categories.map({$0.id}), groups: groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.id}), businesses: businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.id})))
    }
    
    func confirmCategories() {
        confirmedCategories.value = ConfirmedPreference(interests: interests.value, categories: categories.value.filter({$0.selected}).map({$0.category}))
    }
    
    func selectedGroupSuggestion(at index: Int) {
        let item = groupSuggestions.value[index]
        item.selected.value = !item.selected.value
        selectionGroups.value = groupSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
    }
    
    func selectedBusinessSuggestion(at index: Int) {
        let item = businessSuggestions.value[index]
        item.selected.value = !item.selected.value
        selectionsBusiness.value = businessSuggestions.value.filter({$0.selected.value}).map({$0.suggestion.name})
    }
    
}
