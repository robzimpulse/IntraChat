//
//  LocationViewController.swift
//  IntraChat
//
//  Created by Robyarta Ruci on 1/17/18.
//  Copyright © 2018 Personal. All rights reserved.
//

import UIKit
import MapKit

class LocationViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    private var location: CLLocation?
    private var senderName: String?
    let geoCoder: CLGeocoder = CLGeocoder()
    
    lazy var backButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_chevron_left"),style: .plain,target: self,action: #selector(back(_:)))
        button.tintColor = UIColor.white
        return button
    }()
    
    convenience init(senderName: String, location: CLLocation) {
        self.init(nibName: "LocationViewController", bundle: nil)
        self.senderName = senderName
        self.location = location
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = backButton
        guard let location = location else {return}
        let camera = MKMapCamera(lookingAtCenter: location.coordinate,fromDistance: 1000,pitch: 0,heading: 0)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = senderName
        mapView.addAnnotation(annotation)
        mapView.setCamera(camera, animated: false)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemark, _ in
            guard let placemark = placemark?.first else {return}
            self.navigationItem.titleView = self.setTitle(title: placemark.thoroughfare, subtitle: placemark.administrativeArea)
        })
    }

    private func setTitle(title: String?, subtitle: String?) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x:0, y:-5, width:0, height:0))
        
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let subtitleLabel = UILabel(frame: CGRect(x:0, y:18, width:0, height:0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor.lightGray
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x:0, y:0, width:max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height:30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        
        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }
        
        return titleView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        switch (self.mapView.mapType) {
        case MKMapType.hybrid:
            self.mapView.mapType = MKMapType.standard
            break;
        case MKMapType.standard:
            self.mapView.mapType = MKMapType.hybrid
            break;
        default:
            break;
        }
        self.mapView.showsUserLocation = false
        self.mapView.delegate = nil
        self.mapView.removeFromSuperview()
        self.mapView = nil
    }
    
    @objc func map(_ sender: Any) {
        print("open map")
    }
    
    @IBAction func share(_ sender: Any) {
        print("share")
    }
    
    @IBAction func search(_ sender: Any) {
        print("search")
    }
    
    @IBAction func changedValue(_ sender: Any) {
        guard let sender = sender as? UISegmentedControl else {return}
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
            break
        case 1:
            mapView.mapType = .hybrid
            break
        case 2:
            mapView.mapType = .satellite
            break
        default:
            break
        }
    }
    
}

extension LocationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {return nil}
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") else {
            let button = UIButton(x: 0, y: 0, w: 50, h: 50, target: self, action: #selector(map(_:)))
            button.setImage(#imageLiteral(resourceName: "icon_car"), for: .normal)
            button.setBackgroundColor(button.tintColor, forState: .normal)
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            annotationView.animatesDrop = true
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView.leftCalloutAccessoryView = button
            return annotationView
        }
        annotationView.annotation = annotation
        return annotationView
    }
}

