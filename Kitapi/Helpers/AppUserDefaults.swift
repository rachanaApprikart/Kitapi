//
//  AppUserDefaults.swift
//  Kitapi
//
//  Created by Suneel on 14/03/26.
//

import Foundation


struct AppUserDefaults {
    
    static let userDefaults = UserDefaults.standard
    
    
    static var IS_ON_BOARDING_SCREEN_VIEWED: Bool {
        get {
            return self.userDefaults.bool(forKey: "IS_ON_BOARDING_SCREEN_VIEWED")
        }
        set {
            self.userDefaults.setValue(newValue, forKey: "IS_ON_BOARDING_SCREEN_VIEWED")
        }
    }
       
    static var authorizationToken: String? {
        get {
            return self.userDefaults.string(forKey: "authorizationToken") ?? nil
        }
        set {
            self.userDefaults.setValue(newValue, forKey: "authorizationToken")
        }
    }
    
    static var customerDetails: LoggedInParent? {
        get {
            return self.userDefaults.retrieve(object: LoggedInParent.self, fromKey: "LoggedInParent") ?? nil
        }
        set {
            self.userDefaults.save(customObject: newValue, inKey: "LoggedInParent")
        }
    }
    
    //Is Child Mode active?
    
    static var isChildMode: Bool {
        get {
            return self.userDefaults.bool(forKey: "isChildMode")
        }
        set {
            self.userDefaults.setValue(newValue, forKey: "isChildMode")
        }
    }
    
    //When does the Child Mode timer expire?
    
    static var childModeExpiryDate: Date? {
        get {
            return self.userDefaults.object(forKey: "childModeExpiryDate") as? Date
        }
        set {
            self.userDefaults.set(newValue, forKey: "childModeExpiryDate")
        }
    }
}


extension UserDefaults {
    
    func save<T:Encodable>(customObject object: T, inKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            self.set(encoded, forKey: key)
        }
    }
    
    func retrieve<T:Decodable>(object type:T.Type, fromKey key: String) -> T? {
        if let data = self.data(forKey: key) {
            let decoder = JSONDecoder()
            if let object = try? decoder.decode(type, from: data) {
                return object
            } else {
                LogFile.debugMessage(debug: "Couldnt decode object")
                return nil
            }
        } else {
            LogFile.debugMessage(debug: "Couldnt find key")
            return nil
        }
    }
    
}


extension Encodable {
    /// Converts the model to Data using JSONEncoder
    func toData() -> Data? {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self)
            return data
        } catch {
            print("Failed to encode model to Data: \(error.localizedDescription)")
            return nil
        }
    }
}
