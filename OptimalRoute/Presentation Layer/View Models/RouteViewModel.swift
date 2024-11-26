import Foundation
import CoreLocation
import GoogleMaps
import GooglePlaces
import GoogleMaps

class RouteViewModel: ObservableObject {
    
    @Published var originInput: String = ""
    @Published var destinationInput: String = ""
    @Published var waypoints: [String] = []
    @Published var route: GMSPolyline? = nil
    @Published var originCoordinate: CLLocationCoordinate2D? = nil
    @Published var destinationCoordinate: CLLocationCoordinate2D? = nil
    @Published var waypointCoordinates: [CLLocationCoordinate2D] = []
    @Published var totalDistance: String = ""
    @Published var totalDuration: String = ""
    
    
    private let apiKey = GoogleMapsManager.googleAPIKey
    private let placesClient = GMSPlacesClient()
    
    let country: String
    
    init(country: String) {
        self.country = country
    }
    
    
    // Function to reset all inputs
    func reset() {
        originInput = ""
        destinationInput = ""
        waypoints.removeAll()
        route = nil
        originCoordinate = nil
        destinationCoordinate = nil
        waypointCoordinates.removeAll()
        totalDistance = ""
        totalDuration = ""
    }

    func addWaypoint(_ waypoint: String, coordinate: CLLocationCoordinate2D) {
        guard !waypoint.isEmpty, !waypoints.contains(waypoint) else { return }
        waypoints.append(waypoint)
        waypointCoordinates.append(coordinate)
    }
    
    // Function to remove a waypoint
    func removeWaypoint(at index: Int) {
        guard index >= 0 && index < waypoints.count else { return }
        waypoints.remove(at: index)
        waypointCoordinates.remove(at: index)
    }
    
    // Fetch route from Google Directions API
    func fetchRoute() {
        guard let originCoord = originCoordinate,
              let destinationCoord = destinationCoordinate else {
                  return
              }
        
        let baseURL = "https://maps.googleapis.com/maps/api/directions/json?"
        let originParam = "origin=\(originCoord.latitude),\(originCoord.longitude)"
        let destinationParam = "destination=\(destinationCoord.latitude),\(destinationCoord.longitude)"
        let waypointsParam = "waypoints=optimize:true|\(waypointCoordinates.map { "\($0.latitude),\($0.longitude)" }.joined(separator: "|"))"
        
        let travelMode = "mode=driving"
        
        let apiKeyParam = "key=\(apiKey)"
        let urlString = "\(baseURL)\(originParam)&\(destinationParam)&\(waypointsParam)&\(travelMode)&\(apiKeyParam)"
        
       // print(urlString)
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let decoder = JSONDecoder()
                let directionsResponse = try decoder.decode(DirectionsResponse.self, from: data)
                guard let route = directionsResponse.routes.first else {
                    print("No route found")
                    return
                }
                // update ui with route info
                DispatchQueue.main.async {
                    self.route = self.polyline(for: route)
                    self.originCoordinate = originCoord
                    self.destinationCoordinate = destinationCoord
                    //self.totalDistance = route.legs.first?.distance.text ?? ""
                    //self.totalDuration = route.legs.first?.duration.text ?? ""
                    
                    self.calculateTotalDistanceAndDuration(route: route)

                }
            } catch {
                print("Error parsing response: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    
    func calculateTotalDistanceAndDuration(route: Route) {
        var totalDistanceValue = 0
        var totalDurationValue = 0
        
        for leg in route.legs {
            totalDistanceValue += leg.distance.value
            totalDurationValue += leg.duration.value
        }
        
        let distanceInKm = Double(totalDistanceValue) / 1000
        let durationInMinutes = totalDurationValue / 60
        
        self.totalDistance = String(format: "%.2f km", distanceInKm)
        self.totalDuration = "\(durationInMinutes) min"
    }
    
    func getCoordinateFromAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let filter = GMSAutocompleteFilter()
        filter.countries = [country]
        placesClient.findAutocompletePredictions(fromQuery: address, filter: filter, sessionToken: nil) { (results, error) in
            guard let result = results?.first, error == nil else {
                print("Error finding place: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            let placeID = result.placeID
            self.placesClient.fetchPlace(fromPlaceID: placeID, placeFields: .coordinate, sessionToken: nil) { (place, error) in
                guard let place = place, error == nil else {
                    print("Error looking up place: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                completion(place.coordinate)
            }
        }
    }
    
    func getCoordinateFromAddressSync(_ address: String) -> CLLocationCoordinate2D? {
        let semaphore = DispatchSemaphore(value: 0)
        var coordinate: CLLocationCoordinate2D?
        
        getCoordinateFromAddress(address) { coord in
            coordinate = coord
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5) // Wait for 5 seconds for geocoding to complete
        return coordinate
    }
    
    private func polyline(for route: Route) -> GMSPolyline? {
        guard let path = GMSPath(fromEncodedPath: route.overview_polyline.points) else {
            return nil
        }
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 3.0
        return polyline
    }

}

struct DirectionsResponse: Decodable {
    let routes: [Route]
}

struct Route: Decodable {
    let overview_polyline: Polyline
    let legs: [Leg]
}

struct Polyline: Decodable {
    let points: String
}

struct Leg: Decodable {
    let distance: Distance
    let duration: Duration
}

struct Distance: Decodable {
    let text: String
    let value: Int
}

struct Duration: Decodable {
    let text: String
    let value: Int
}



