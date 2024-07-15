//
//  AppDelegate.swift
//  OptimalRoute
//
//  Created by MacBook Pro2 2022 on 09/07/2024.
//

import UIKit
import GoogleMaps
import GooglePlaces


class GoogleMapsManager: NSObject {
    
    static let shared = GoogleMapsManager()
    
    // Define static constants
    static let googleAPIKey = "AIzaSyDQMzgJCxOtw-w1j1ifTjnajNNoaNzl_f4"

    static let country = "uk"

    private override init() {
        super.init()
        GMSServices.provideAPIKey(GoogleMapsManager.googleAPIKey)
        GMSPlacesClient.provideAPIKey(GoogleMapsManager.googleAPIKey)
    }
}
