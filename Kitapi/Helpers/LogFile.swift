//
//  Logfile.swift
//  VIM
//
//  Created by Rachana on 31/05/24.
//
import Foundation

let Debug = true



struct LogFile {
    static func warningMessage(warning message: String) {
        if Debug {
            print("!!!!!!!!!!!!!!!!!!!!! WARNING MESSAGE !!!!!!!!!!!!!!!!", message)
        }
       
    }
    
    static func debugMessage(debug message: String, value: Any? = nil) {
        if Debug {
            
            if let respValue = value {
                print("\n===\(message)====", respValue)
            } else {
                print("================", message)
            }
           
        }
    }
    
}
