//
//  CompareNetworking.swift
//  RideCompare
//
//  Created by Robert Cash on 2/15/17.
//  Copyright © 2017 Robert Cash. All rights reserved.
//

import Foundation

protocol CompareNetworking: Networking {
    func getComparison(startCoordinate:(Double, Double), endCoordinate:(Double, Double), completion: @escaping (_ result: (Bool, String)) -> Void)
}

extension CompareNetworking {
    func getComparison(startCoordinate:(Double, Double), endCoordinate:(Double, Double), completion: @escaping (_ result: (Bool, String)) -> Void) {
        let queue = DispatchQueue(label: "Compare")
        
        queue.async(qos:.userInitiated) {
            let params = [
                "start_lng":startCoordinate.1,
                "start_lat":startCoordinate.0,
                "end_lat":endCoordinate.0,
                "end_lng":endCoordinate.1
            ]
            let r = self.postRequest(endpoint: "compare", params: params)
            
            let result: (Bool, String)
            
            if let _ = r["error"].bool {
                result = (false, "connection_error")
            }
            else if !r["success"].boolValue {
                result = (false, "server_error")
            }
            else {
                result = (true, r["winner"].stringValue)
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
