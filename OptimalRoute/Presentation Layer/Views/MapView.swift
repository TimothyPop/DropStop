

import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {
    @Binding var route: GMSPolyline?
    @Binding var originCoordinate: CLLocationCoordinate2D?
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    var originAddress: String
    var destinationAddress: String
    var waypointCoordinates: [CLLocationCoordinate2D]
    var waypointAddresses: [String]
    @Binding var mapType: GMSMapViewType

    var onTap: (() -> Void)? // Closure to handle tap events


    func makeUIView(context: Context) -> GMSMapView {
        let mapView = GMSMapView(frame: .zero)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.delegate = context.coordinator
        //GoogleMapsManager.shared.mapView = mapView // Store the mapView reference in the shared manager


        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        
        mapView.mapType = mapType
        mapView.clear()
        
        // Add origin marker
        if let originCoordinate = originCoordinate {
            let marker = GMSMarker(position: originCoordinate)
            marker.title = "Origin"
            marker.snippet = originAddress
            marker.map = mapView
            marker.icon = GMSMarker.markerImage(with: .orange)
        }
        
        // Add destination marker
        if let destinationCoordinate = destinationCoordinate {
            let marker = GMSMarker(position: destinationCoordinate)
            marker.title = "Destination"
            marker.snippet = destinationAddress
            marker.map = mapView
            marker.icon = GMSMarker.markerImage(with: .green)

        }
      
        // Add markers for waypoints
        for (index, coordinate) in waypointCoordinates.enumerated() {
            let marker = GMSMarker(position: coordinate)
            marker.title = waypointAddresses[index]
            marker.icon = GMSMarker.markerImage(with: .blue)
            marker.map = mapView
        }
        
        if let path = route?.path {
            // Create the arrow icon once and reuse it
            let arrowIcon = drawArrowIcon(size: CGSize(width: 25, height: 20), color: .green)
            
            for index in stride(from: 0, to: path.count(), by: 30) {
                let coordinate = path.coordinate(at: index)
                let nextIndex = index + 1 < path.count() ? index + 1 : index
                let nextCoordinate = path.coordinate(at: nextIndex)
                
                let arrowMarker = GMSMarker(position: coordinate)
                arrowMarker.icon = arrowIcon // Reuse the same icon
                
                // Calculate the bearing only if nextIndex is different
                if index != nextIndex {
                    arrowMarker.rotation = CLLocationDegrees(coordinate.bearing(to: nextCoordinate))
                }
                
                arrowMarker.map = mapView
            }
        }
        
        // Add route
        route?.map = mapView
        
        // Adjust camera to fit all markers
        var bounds = GMSCoordinateBounds()
        if let originCoordinate = originCoordinate {
            bounds = bounds.includingCoordinate(originCoordinate)
        }
        if let destinationCoordinate = destinationCoordinate {
            bounds = bounds.includingCoordinate(destinationCoordinate)
        }
        for waypoint in waypointCoordinates {
            bounds = bounds.includingCoordinate(waypoint)
        }
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50)
        mapView.moveCamera(update)
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onTap: onTap)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
            var parent: MapView
            var onTap: (() -> Void)?

            init(_ parent: MapView, onTap: (() -> Void)?) {
                self.parent = parent
                self.onTap = onTap
            }

            func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
                onTap?()
            }
        }
}


extension CLLocationCoordinate2D {

    func bearing(to coordinate: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude.toRadians()
        let lon1 = self.longitude.toRadians()
        let lat2 = coordinate.latitude.toRadians()
        let lon2 = coordinate.longitude.toRadians()
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        return bearing.toDegrees()
    }
}


//func drawArrowIcon(size: CGSize, color: UIColor) -> UIImage? {
//    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
//    guard let context = UIGraphicsGetCurrentContext() else { return nil }
//
//    context.setFillColor(color.cgColor)
//    
//    // Draw an arrow pointing upwards
//    context.move(to: CGPoint(x: size.width / 2, y: 0))
//    context.addLine(to: CGPoint(x: size.width, y: size.height))
//    context.addLine(to: CGPoint(x: 0, y: size.height))
//    context.closePath()
//    
//    context.fillPath()
//    
//    let arrowImage = UIGraphicsGetImageFromCurrentImageContext()
//    UIGraphicsEndImageContext()
//    
//    return arrowImage
//}

/*
func drawArrowIcon(size: CGSize, color: UIColor, outlineColor: UIColor = .black) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }

    // Draw the arrow with an outline
    let outlineWidth: CGFloat = 2.0

    // Draw the arrow
    context.setFillColor(color.cgColor)
    context.setLineWidth(outlineWidth)
    context.setStrokeColor(outlineColor.cgColor)
    
    // Create the arrow path
    context.move(to: CGPoint(x: size.width / 2, y: 0))
    context.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.5))
    context.addLine(to: CGPoint(x: size.width * 0.75, y: size.height))
    context.addLine(to: CGPoint(x: size.width * 0.25, y: size.height))
    context.addLine(to: CGPoint(x: size.width * 0.25, y: size.height * 0.5))
    context.closePath()
    
    context.drawPath(using: .fillStroke)
    
    let arrowImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return arrowImage
}

*/


func drawArrowIcon(size: CGSize, color: UIColor, outlineColor: UIColor = .black) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    defer { UIGraphicsEndImageContext() } // Ensure context is ended properly
    guard let context = UIGraphicsGetCurrentContext() else { return nil }

    // Set colors and line width
    context.setFillColor(color.cgColor)
    context.setLineWidth(2.0)
    context.setStrokeColor(outlineColor.cgColor)
    
    // Create a more concise and modern arrow path
    let arrowWidth = size.width * 0.6
    let arrowHeight = size.height * 0.4
    let centerX = size.width / 2
    let centerY = size.height / 2

    context.move(to: CGPoint(x: centerX, y: 0))
    context.addLine(to: CGPoint(x: centerX + arrowWidth / 2, y: arrowHeight))
    context.addLine(to: CGPoint(x: centerX + arrowWidth / 4, y: arrowHeight))
    context.addLine(to: CGPoint(x: centerX + arrowWidth / 4, y: size.height))
    context.addLine(to: CGPoint(x: centerX - arrowWidth / 4, y: size.height))
    context.addLine(to: CGPoint(x: centerX - arrowWidth / 4, y: arrowHeight))
    context.addLine(to: CGPoint(x: centerX - arrowWidth / 2, y: arrowHeight))
    context.closePath()
    
    // Draw the path with fill and stroke
    context.drawPath(using: .fillStroke)
    
    // Retrieve the image
    return UIGraphicsGetImageFromCurrentImageContext()
}




extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }

    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}
