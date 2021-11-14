//
//  ViewController.swift
//  Inrix Hacks
//
//  Created by Gavin Ryder on 11/13/21.
//

import UIKit
import MapKit

// MARK: - RiskMap
struct RiskMap: Codable {
    let routes: [Route]
}

// MARK: - Route
struct Route: Codable {
    let boundingBox: BoundingBox
    let id: String
    let points: [[Double]]
    let risk: Risk
}

// MARK: - BoundingBox
struct BoundingBox: Codable {
    let center: [Double]
    let radius: Double
}

// MARK: - Risk
struct Risk: Codable {
    let incidents, slowdown, speed, time, weather: Double
    let total: Int
}

func fetchRisk(completion: @escaping (_ riskMap: RiskMap?, _ error: Error?)->()) {
    let url = URL(string: "http://127.0.0.1:5000/" + "risk")!
    var request = URLRequest(url: url)
    let t = URLSession.shared.dataTask(with: request)
    { data, response, error in
        guard let data = data,
                  error == nil else
        {
            completion(nil, error)
            return
        }
        let riskMap = try? JSONDecoder().decode(RiskMap.self, from: data)
        completion(riskMap, error)
    }
    t.resume()
}

class ViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: Oulets
    @IBOutlet weak var mapView: MKMapView! //mapKit view
    @IBOutlet var superView: UIView!
    
    @IBOutlet weak var button1: UIButtonWithRoutedMap!
    @IBOutlet weak var button2: UIButtonWithRoutedMap!
    @IBOutlet weak var button3: UIButtonWithRoutedMap!
    
    var testRegion = MKCoordinateRegion()
    
    var riskScores = Risk(incidents: 0, slowdown: 0, speed: 0, time: 0, weather: 0, total: 0)
    
    var locations = [
        CLLocation(latitude: 37.78073, longitude: -122.47236),
        CLLocation(latitude: 37.78697, longitude: -122.41154),
        CLLocation(latitude: 37.78758, longitude: -122.42360)         
            ]
    
    
    
    
    func setupButtons() {
        testRegion = mapView.region
        
        let rMap = RoutedMap(region: testRegion, riskScores: riskScores, routePoints: locations)
        
        button1.mapRoute = rMap
        button2.mapRoute = rMap
        button3.mapRoute = rMap
        
//        button1.addTarget(self, action: #selector(pressedButton(sender:)), for: .touchUpInside)
//        button2.addTarget(self, action: #selector(pressedButton(sender:)), for: .touchUpInside)
//        button3.addTarget(self, action: #selector(pressedButton(sender:)), for: .touchUpInside)
    }
    
    @objc func pressedButton(sender: Any) {
        let group = DispatchGroup()
            group.enter()
            
            fetchRisk()
            { riskMap, error in
                    //print(self.convertRawRiskMapToRouted(riskMap!).routePoints)
                    self.button1.setMapRoute(self.convertRawRiskMapToRouted(riskMap!))
                    group.leave()
            }
        
            group.wait()
    }
    
    func convertRawRiskMapToRouted(_ riskMap: RiskMap) -> RoutedMap {
        let route = riskMap.routes.first
        let boundingBox: BoundingBox = route!.boundingBox
        let center = CLLocationCoordinate2DMake(boundingBox.center[1], boundingBox.center[0])
        print(boundingBox.radius)
        let mapRegion = MKCoordinateRegion(center: center, latitudinalMeters: boundingBox.radius*1.5, longitudinalMeters: boundingBox.radius*1.5)
        
        var coords:[CLLocation] = []
        for point in route!.points {
            coords.append(CLLocation(latitude: point[1], longitude: point[0]))
        }
        print(coords)
        
        let risk = route!.risk
        
        let routedMap:RoutedMap = RoutedMap(region: mapRegion, riskScores: risk, routePoints: coords)
        
        return routedMap
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "button1") {
            pressedButton(sender: button1)
            (segue.destination as! SelectedView).mapWithRoute = button1.mapRoute
        } else if (segue.identifier == "button2") {
            (segue.destination as! SelectedView).mapWithRoute = button2.mapRoute
        } else if (segue.identifier == "button3") {
            (segue.destination as! SelectedView).mapWithRoute = button3.mapRoute
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupMap()
        setupButtons()
        //DispatchQueue.main.async {
        //}
    }
    
    func setupMap() {
        let centerCoord:CLLocationCoordinate2D = CLLocationCoordinate2DMake(37.778, -122.441)
        let region = MKCoordinateRegion.init(center: centerCoord, latitudinalMeters: 9200, longitudinalMeters: 9200)
        mapView.setRegion(region, animated: true)
    }
    
}

class UIButtonWithRoutedMap: UIButton {
    var mapRoute: RoutedMap = RoutedMap()
    
    func setMapRoute(_ routedMap: RoutedMap) {
        mapRoute = routedMap
        print("set!")
    }
}


