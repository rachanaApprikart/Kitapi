//
//  String+PhoneNumberValidation.swift
//  StyleTribute
//
//  Created by Suneel on 01/04/26.
//

import Foundation
import UIKit

extension String {
    func allowOnlyDigits() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: ".*[0-9].*", options: [])
            if regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) != nil {
                return false
            }
        } catch {
            // print("ERROR")
        }
        return true
    }
        
    func allowOnlyCharcters() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: ".*[^A-Za-z ].*", options: [])
            if regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) != nil {
                return false
            }
        } catch {
            //  print("ERROR")
        }
        return true
    }    
    
    func allowDigitsAndCharacters() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: ".*[^A-Za-z0-9 ].*", options: [])
            if regex.firstMatch(in: self, options: [], range: NSMakeRange(0, self.count)) != nil {
                return false
            }
        }
        catch {
            //  print("ERROR")
        }
        return true
    }
    func isValidIndianPhoneWithCode() -> Bool {
        let regex = "^(\\+91|91)?[6-9]\\d{9}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }
    
    func isValidIndianPhone() -> Bool {
        let PHONE_REGEX = "[6789][0-9]{9}"
        let phoneTest:NSPredicate = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result:Bool = phoneTest.evaluate(with: self)
        return result
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
    
    func checkPasswordStrength() -> PasswordStrength {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@#$%^&+=])(?!.*\\s).{8,}$"
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        if passwordTest.evaluate(with: self) {
            if self.count >= 8 && self.count <= 10 {
                return .weak
            } else if self.count > 10 && self.count <= 12 {
                return .moderate
            } else {
                return .strong
            }
        } else {
            return .weak
        }
    }
    
    func checkForNumberCount(charsLimit: Int, textField: UITextField, range: NSRange) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: self)
        let numberDigit = allowedCharacters.isSuperset(of: characterSet)
        if numberDigit {
            let startingLength = textField.text?.count ?? 0
            let lengthToAdd = self.count
            let lengthToReplace =  range.length
            let newLength = startingLength + lengthToAdd - lengthToReplace
            return newLength <= charsLimit
        }
        return false
    }
    
    func queryString(params: [String: String]) -> String? {
        var components = URLComponents(string: self)
        components?.queryItems = params.map { element in URLQueryItem(name: element.key, value: element.value) }
        
        return components?.url?.absoluteString
    }
}


extension String {
    
    func getCountryCodeAndPhoneNumberFromString() -> (countyCode: String, phoneNumber: String)? {
        
       let splitArray = self.split(separator: " ")
        
        guard (splitArray.count == 2) else {
            return nil
        }
        let countryCodeVal = String(splitArray[0])
        let phoneNumberVal = String(splitArray[1])
        
        return (countyCode: countryCodeVal, phoneNumber: phoneNumberVal)
    }
    
}

enum PasswordStrength {
    case weak
    case moderate
    case strong
}

