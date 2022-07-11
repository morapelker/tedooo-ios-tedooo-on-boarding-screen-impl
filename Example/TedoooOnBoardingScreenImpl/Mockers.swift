//
//  Mockers.swift
//  TedoooOnBoardingScreenImpl_Example
//
//  Created by Mor on 07/07/2022.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import TedoooCategoriesApi
import Combine
import TedoooOnBoardingApi
import CreateShopFlowApi

class Mockers: CategoriesProvider, TedoooOnBoardingApi, CreateShopFlowApi {
  
    func hasSuggestions() -> AnyPublisher<Bool, Never> {
        return Just(true).delay(for: 1.0, scheduler: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    func startFlow(in viewController: UIViewController, fromOnBoarding: Bool) -> AnyPublisher<AddShopResult, AddShopError> {
        let vc = UIViewController()
        vc.view.backgroundColor = .red
        vc.modalPresentationStyle = .overCurrentContext
        viewController.present(vc, animated: true)
//        navController.pre(vc, animated: true)
        let subject = PassthroughSubject<AddShopResult, AddShopError>()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            subject.send(AddShopResult.init(vc: vc, id: "id", action: .showBusinessProfile))
        }
        return subject.eraseToAnyPublisher()
    }
    
    func startEditFlow(in viewController: UIViewController, request: EditShopFlowRequest) -> AnyPublisher<AddShopResult, AddShopError> {
        return Fail(error: AddShopError.flowCancelled(UIViewController())).eraseToAnyPublisher()
    }
    
    
    func finishOnBoarding(request: FinishOnBoardingRequest) -> AnyPublisher<Any?, Never> {
        print("finish onboarding", request)
        return Just(nil).delay(for: 1.0, scheduler: DispatchQueue.main).eraseToAnyPublisher()
    }
   
    private var didInit = false
    
    static let shared = Mockers()
    
    
    
    func provideCategories() -> ProvideCategoriesResponse {
        let categories = [
            Category.init(id: "CategoryId1", text: "text", baseImage: UIImage(systemName: "xmark"), image: ""),
            Category.init(id: "CategoryId2", text: "text", baseImage: UIImage(systemName: "square"), image: ""),
            Category.init(id: "CategoryId3", text: "text", baseImage: UIImage(systemName: "octagon"), image: "")
        ]
        if didInit {
            return ProvideCategoriesResponse(instant: true, subject: Just(categories).eraseToAnyPublisher())
        }
        didInit = true
        return ProvideCategoriesResponse(instant: false, subject: Just(categories).delay(for: 1.0, scheduler: DispatchQueue.main).eraseToAnyPublisher())
    }
    
    func getBusinessSuggestions(interests: [String]) -> AnyPublisher<[BusinessSuggestion], Never> {
        print("fetching business suggestions")
        return Just([
            BusinessSuggestion(id: "shopId1", name: "TwoSisterHomenBridal.etsy.com", rating: 5, totalReviews: 900, categories: ["Handmade Crafts", "Textile", "Handmade Crafts", "Textile"], description: "description", image: "https://i.imgur.com/sBmKIeD.png"),
            BusinessSuggestion(id: "ShopId2", name: "Shop 2", rating: 4, totalReviews: 450, categories: ["Handmade Crafts", "Textile", "Homemade"], description: "description", image: nil),
            BusinessSuggestion(id: "ShopId3", name: "Shop 3", rating: 3.5, totalReviews: 1358, categories: ["Tests", "Textile"], description: "description", image: "https://i.imgur.com/r4PtogW.png")
        ]).delay(for: 2.0, scheduler: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    func getGroupSuggestions(interests: [String]) -> AnyPublisher<[GroupSuggestion], Never> {
        print("fetching group suggestions")
        return Just([
            GroupSuggestion(id: "GroupId1", name: "Wreath lovers", participants: 1500, description: "Hi there! this group is for people who are interested in Crafty fun and handmade items", image: "https://i.imgur.com/sBmKIeD.png"),
GroupSuggestion(id: "GroupId2", name: "Crafty fun", participants: 31010, description: "Our group is made to support crafters and handmade creators meet and share tips", image: "https://i.imgur.com/r4PtogW.png"),
GroupSuggestion(id: "GroupId3", name: "Handmade fans", participants: 456, description: "Our group is made to support crafters and handmade creators meet and share tips!", image: nil),
        ]).delay(for: 3.0, scheduler: DispatchQueue.main).eraseToAnyPublisher()
    }
    
}
