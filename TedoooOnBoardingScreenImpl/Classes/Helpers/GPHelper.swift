//
//  GPHelper.swift
//  TedoooOnBoardingScreenImpl
//
//  Created by Mor on 06/07/2022.
//

import Foundation
import UIKit

class GPHelper {
    
    static let shared = GPHelper()
    
    static func instantiateViewController<T: UIViewController>(type: T.Type) -> T {
        return UIStoryboard(name: "Main", bundle: Bundle(for: InitialViewController.self)).instantiateViewController(withIdentifier: String(describing: type)) as! T
    }
    
    static func participantsToString(participants: Int) -> String {
        if participants >= 1000 {
            let participantString = String(format: "%.1f", Double(participants) / 1000)
            let str = participantString.trimSuffix(".0")
            return "\(str)k"
        }
        return String(participants)
    }
}

extension String {
    
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    
    func lastIndexOf(_ input: String) -> String.Index? {
        return index(of: input, options: .backwards)
    }
    
    func trimSuffix(_ suffix: String) -> String {
        if self.hasSuffix(suffix) {
            let index = self.lastIndexOf(suffix)
            return String(self[..<index!])
        }
        return self
    }
    
}
