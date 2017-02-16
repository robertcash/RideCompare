//
//  CompareViewController.swift
//  RideCompare
//
//  Created by Robert Cash on 2/15/17.
//  Copyright © 2017 Robert Cash. All rights reserved.
//

import UIKit
import GooglePlaces
import CoreLocation

class CompareViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var destinationButton: UIButton!
    
    // MARK: - Variables 
    
    var locationManager: CLLocationManager!
    var startLat: Double?
    var startLng: Double?
    var endLat: Double?
    var endLng: Double?
    
    // MARK: UIViewController Lifecycle Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up CLLocationManager to get locational data
        self.setUpCLLocationManager()
        self.setUpUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UI Functions
    
    func setUpUI() {
        // Finish actionButton's look
        self.actionButton.layer.cornerRadius = 10
        self.actionButton.clipsToBounds = true
        
        // Finsh resultImageView's look
        self.resultImageView.layer.cornerRadius = 10
        self.resultImageView.clipsToBounds = true
        self.resultImageView.contentMode = .scaleAspectFit
    }
    
    func showWinner(winner: String) {
        if winner == "lyft" {
            self.actionButton.setTitle("Open Lyft", for: .normal)
            self.resultImageView.image = #imageLiteral(resourceName: "lyft")
        }
        else {
            self.actionButton.setTitle("Open Uber", for: .normal)
            self.resultImageView.backgroundColor = .black
            self.resultImageView.image = #imageLiteral(resourceName: "uber")
        }
    }
    
    
    // MARK: - IBAction Functions
    
    @IBAction func enterDestination(_ sender: Any) {
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    @IBAction func doAction(_ sender: Any) {
        if self.actionButton.titleLabel?.text == "Compare" && self.endLat != nil {
                self.doComparison()
        }
        else if self.actionButton.titleLabel?.text == "Open Uber" {
            let uberUrl = URL(string: "uber://?action=setPickup&pickup[latitude]=\(self.startLat!)&pickup[longitude]=\(self.startLng!)&dropoff[latitude]=\(self.endLat!)&dropoff[longitude]=\(self.endLng!)")
            UIApplication.shared.openURL(uberUrl!)
        }
        else if self.actionButton.titleLabel?.text == "Open Lyft" {
            // Open Lyft
            let lyftUrl = URL(string: "lyft://ridetype?id=lyft_line&pickup[latitude]=\(self.startLat!)&pickup[longitude]=\(self.startLng!)&destination[latitude]=\(self.endLat!)&destination[longitude]=\(self.endLng!)")
            UIApplication.shared.openURL(lyftUrl!)
        }
        else {
            self.showErrorMessage(type: 1)
        }
    }
    
    // MARK: - UIAlertController Functions
    
    func showErrorMessage(type: Int) {
        var errorMessage: String!
        
        switch type {
        case 0:
            errorMessage = "Connection error! Try again!"
            break
        case 1:
            errorMessage = "You need to enter a destination first!"
            break
        case 2:
            errorMessage = "Something went wrong, please try again later!"
        default:
            errorMessage = "Connection error! Try again!"
            break
        }
        
        // Show error alert
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showLocationErrorMessage() {
        let errorMessage = "You must allow location permissions for RideCompare to find you price estimates! Please go to settings to give us location permissions!"
        
        // Show error alert
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    })
                }
                else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
        }
        
        alert.addAction(settingsAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

}

extension CompareViewController: CompareNetworking {
    func doComparison() {
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        getComparison(startCoordinate: (self.startLat!, self.startLng!), endCoordinate: (self.endLat!, self.endLng!)) { [unowned self] (result: (Bool, String)) in
            PKHUD.sharedHUD.hide()
            
            if !result.0 && result.1 == "server_error" {
                self.showErrorMessage(type: 2)
            }
            else if !result.0 && result.1 == "connection_error" {
                self.showErrorMessage(type: 0)
            }
            else {
                self.showWinner(winner: result.1)
            }
        }
        
    }
}

extension CompareViewController: CLLocationManagerDelegate {
    func setUpCLLocationManager() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // Update users location
            self.locationManager.startUpdatingLocation()
        }
        if status == .denied {
            // Show error message that user should go to settings to add location or else tracking won't work.
            self.showLocationErrorMessage()
            self.actionButton.isEnabled = false
            self.destinationButton.isEnabled = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        self.startLat = location?.coordinate.latitude
        self.startLng = location?.coordinate.longitude
    }
}

extension CompareViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // Get destination details
        self.destinationTextField.text = place.name
        self.endLat = place.coordinate.latitude
        self.endLng = place.coordinate.longitude
        
        // Setup UI
        self.actionButton.setTitle("Compare", for: .normal)
        self.resultImageView.image = nil
        self.resultImageView.backgroundColor = .white
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: \(error)")
        dismiss(animated: true, completion: nil)
    }
    
    // User cancelled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        print("Autocomplete was cancelled.")
        dismiss(animated: true, completion: nil)
    }
}
