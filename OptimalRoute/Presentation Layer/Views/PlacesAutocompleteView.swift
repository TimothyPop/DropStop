import SwiftUI
import GooglePlaces

struct PlacesAutocompleteView: UIViewControllerRepresentable {
    @Binding var selectedPlace: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?

    
    var country: String

    func makeUIViewController(context: Context) -> GMSAutocompleteViewController {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator

        let filter = GMSAutocompleteFilter()
        filter.countries = [country]
        autocompleteController.autocompleteFilter = filter

        return autocompleteController
    }

    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, GMSAutocompleteViewControllerDelegate {
        var parent: PlacesAutocompleteView

        init(_ parent: PlacesAutocompleteView) {
            self.parent = parent
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            parent.selectedPlace = place.formattedAddress ?? ""
            parent.selectedCoordinate = place.coordinate
            viewController.dismiss(animated: true, completion: nil)
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: \(error.localizedDescription)")
            viewController.dismiss(animated: true, completion: nil)
        }

        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
}
