//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit

class TheatersMapViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    var currentElement: String!
    var theater: Theater!
    var theaters: [Theater] = []
    
    //lazy força a instancia apenas quando for usar, usa-se por boas praticas para instancias mais pesadas
    lazy var locationManager = CLLocationManager()
    
    var poiAnnotations: [MKPointAnnotation] = []
    
    // MARK: - Super Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadXML()
        requestUserlocationAuthorization()
    }
    
    // MARK: - Methods
    func loadXML() {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xml) else {return}
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for theater in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            
            let annotation = TheaterAnnotation(coordinate: coordinate, title: theater.name, subtitle: theater.address)
            
            mapView.addAnnotation(annotation)
        }
        
    }
    
    func requestUserlocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            //nivel de precisão, quanto mais precisao, maior o consumo de bateria
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            //atualiza a localização em Background
            //locationManager.allowsBackgroundLocationUpdates = true
            //ele analisa se é necessário o ipdate e intervalos
            locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                print("Usuario já autorizou o uso da localização")
            case .denied:
                print("Usuario negou a autrização")
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("Sifu!")
       //     default:
         //       break
                
            }
            
        }
        
    }
}

// MARK: - XMLParserDelegate
extension TheatersMapViewController: XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentElement = elementName
        
        if elementName == "Theater" {
            theater = Theater()
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        print(string)
        
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            switch currentElement {
            case "name":
                theater.name = content
            case "address":
                theater.address = content
            case "latitude":
                theater.latitude = Double(content)!
            case "longitude":
                theater.longitude = Double(content)!
            case "url":
                theater.url = content
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if elementName == "Theater" {
            theaters.append(theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
    
}

//MARK: - MKMapViewDelegate

extension TheatersMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView: MKAnnotationView!
        
        if annotation is TheaterAnnotation {
            
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Thearter")
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
                
            } else
            {
                annotationView.annotation = annotation
                
            }
            
        }
        
        return annotationView
        
    }
    
}
//verifica em tempo real se o usuario autorizou ou negou a permissão
extension TheatersMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
        default:
            break
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Velocidade do usuario: \(userLocation.location?.speed ?? 0)")
        
        //pegando a localização do usuário
        //let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500)
        //mapView.setRegion(region, animated: true)
    }
    
}

extension TheatersMapViewController: UISearchBarDelegate {
    //requisição fornecida pela Apple
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text!
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
        if error == nil {
            guard let response = response else {return}
            self.mapView.removeAnnotation(self.poiAnnotations as! MKAnnotation)
            self.poiAnnotations.removeAll()
            
            for item in response.mapItems {
                let place = MKPointAnnotation()
                place.coordinate = item.placemark.coordinate
                place.title = item.placemark.name
                place.subtitle = item.phoneNumber
                self.poiAnnotations.append(place)
            }
            self.mapView.addAnnotations(self.poiAnnotations)
            
            }
        }
        
    }
    
}








