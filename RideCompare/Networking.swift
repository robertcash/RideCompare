//
//  Networking.swift
//  RideCompare
//
//  Created by Robert Cash on 2/15/17.
//  Copyright © 2017 Robert Cash. All rights reserved.
//

import Foundation

protocol Networking {
    func postRequest(endpoint: String, params: Dictionary<String, Any>) -> JSON
    func getRequest(endpoint: String) -> JSON
}

extension Networking {
    func postRequest(endpoint:String, params:Dictionary<String, Any>) -> JSON {
        let r = Just.post(API_URL + endpoint, json:params, timeout:300)
        
        print(params)
        if r.ok && r.statusCode == 200 {
            let json = JSON(r.json!)
            return json
        }
        
        return JSON(["error":true])
    }
    
    func getRequest(endpoint:String) -> JSON {
        let r = Just.get(API_URL + endpoint)
        
        if r.ok && r.statusCode == 200 {
            let json = JSON(r.json!)
            return json
        }
        
        return JSON(["error":true])
    }
}
