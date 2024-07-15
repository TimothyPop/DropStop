

import SwiftUI
import GoogleMaps


struct RouteMainView: View {
    
    @StateObject private var viewModel: RouteViewModel
    @State private var showOriginAutocomplete = false
    @State private var showDestinationAutocomplete = false
    @State private var newWaypointInput: String = ""
    @State private var newWaypointCoordinate: CLLocationCoordinate2D?
    @State private var showWaypointAutocomplete = false
    
    @State private var showWayPointsView = false
    @State private var showTopView = true
    @State private var mapType: GMSMapViewType = .normal
    @Environment(\.colorScheme) var colorScheme
    
    
    init() {
        let country = GoogleMapsManager.country
        _viewModel = StateObject(wrappedValue: RouteViewModel(country: country))
        // Initialize Google Maps SDK
        _ = GoogleMapsManager.shared
    }
    
    var body: some View {
      
        NavigationView {
            
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    
                    
                    // Map View with tap gesture
                    MapView(route: $viewModel.route,
                            originCoordinate: $viewModel.originCoordinate,
                            destinationCoordinate: $viewModel.destinationCoordinate,
                            originAddress: viewModel.originInput,
                            destinationAddress: viewModel.destinationInput,
                            waypointCoordinates: viewModel.waypointCoordinates, waypointAddresses: viewModel.waypoints,mapType: $mapType,
                            onTap: {
                        print("click on MapView")
//                        withAnimation {
//                            showTopView.toggle()
//                        }
                        
                        withAnimation(.easeInOut(duration: 1.0)) {
                            showTopView.toggle()
                        }
                    })
                    .edgesIgnoringSafeArea(.all)
                    
                    
                    // VStack {
                    // Top view
                    if showTopView {
                        VStack {
                            
                            // Map Type Picker
                            Picker("Map Type", selection: $mapType) {
                                Text("Normal").tag(GMSMapViewType.normal)
                                Text("Satellite").tag(GMSMapViewType.satellite)
                                Text("Terrain").tag(GMSMapViewType.terrain)
                                Text("Hybrid").tag(GMSMapViewType.hybrid)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            
                            // Origin Button and Autocomplete
                            Button(action: {
                                showOriginAutocomplete = true
                            }) {
                                HStack {
                                    Text(viewModel.originInput.isEmpty ? "Enter Origin" : viewModel.originInput)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(viewModel.originInput.isEmpty ? .gray : .primary)
                                    Spacer()
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.white))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                            }
                            .sheet(isPresented: $showOriginAutocomplete) {
                                PlacesAutocompleteView(selectedPlace: $viewModel.originInput, selectedCoordinate: $viewModel.originCoordinate, country: viewModel.country)
                            }
                            .padding(.horizontal)
                            
                            // Destination Button and Autocomplete
                            Button(action: {
                                showDestinationAutocomplete = true
                            }) {
                                HStack {
                                    Text(viewModel.destinationInput.isEmpty ? "Enter Destination" : viewModel.destinationInput)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(viewModel.destinationInput.isEmpty ? .gray : .primary)
                                    Spacer()
                                }
                                .padding()
                                //.background(Color(UIColor.systemBackground))
                                .background(colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.white))
                                
                                .cornerRadius(10)
                                .shadow(radius: 2)
                            }
                            .sheet(isPresented: $showDestinationAutocomplete) {
                                PlacesAutocompleteView(selectedPlace: $viewModel.destinationInput, selectedCoordinate: $viewModel.destinationCoordinate, country: viewModel.country)
                            }
                            .padding(.horizontal)
                            
                            // Waypoints Input and Autocomplete
                            VStack {
                                HStack {
                                    Button(action: {
                                        showWaypointAutocomplete = true
                                    }) {
                                        HStack {
                                            Text(newWaypointInput.isEmpty ? "Enter Drop off" : newWaypointInput)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(newWaypointInput.isEmpty ? .gray : .primary)
                                            Spacer()
                                        }
                                        .padding()
                                        //.background(Color(UIColor.systemBackground))
                                        .background(colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.white))
                                        
                                        .cornerRadius(10)
                                        .shadow(radius: 2)
                                    }
                                }
                                .sheet(isPresented: $showWaypointAutocomplete) {
                                    PlacesAutocompleteView(selectedPlace: $newWaypointInput, selectedCoordinate: $newWaypointCoordinate, country: viewModel.country)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Total Distance and Duration
                            if (viewModel.route != nil) {
                                HStack {
                                    Text("Total Distance: \(viewModel.totalDistance)")
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(.leading)
                                    Spacer()
                                    Text("Total Duration: \(viewModel.totalDuration)")
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(.trailing)
                                }
                                .padding(.vertical)
                            }
                            
                            
                            Button(action: {
                                if let coordinate = newWaypointCoordinate {
                                    viewModel.addWaypoint(newWaypointInput, coordinate: coordinate)
                                    newWaypointInput = ""
                                    newWaypointCoordinate = nil
                                }
                            }) {
                                Text("Add Stop")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: (geometry.size.width - 100) / 2)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            
                            HStack {
                                HStack(spacing: 10) {
                                    Button(action: {
                                        viewModel.fetchRoute()
                                    }) {
                                        Text("Calculate Route")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: (geometry.size.width - 100) / 2)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                    }
                                    
                                    if !viewModel.originInput.isEmpty || !viewModel.destinationInput.isEmpty || !viewModel.destinationInput.isEmpty || !viewModel.waypoints.isEmpty || (viewModel.route != nil) {
                                        Button(action: {
                                            viewModel.reset()
                                            newWaypointInput = ""
                                            newWaypointCoordinate = nil
                                        }) {
                                            Text("Reset")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: (geometry.size.width - 100) / 2)
                                                .padding()
                                                .background(Color.red)
                                                .cornerRadius(10)
                                                .shadow(radius: 5)
                                        }
                                        //.padding(.top)
                                    }
                                }
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 15)
                            .frame(height: 60) // Adjust the height as needed
                            
                        }
                        .navigationBarTitle("Route", displayMode: .inline)
                        //.padding(.top, 80)
                        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                        .navigationBarItems(trailing: NavigationLink(destination: WayPointsListView(viewModel: viewModel)) {
                            ZStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.blue)
                                if viewModel.waypoints.count > 0 {
                                    Text(viewModel.waypoints.count > 9 ? "10+" :   "\(viewModel.waypoints.count)")
                                        .font(.system(size: viewModel.waypoints.count > 9 ? 15: 20))
                                        .foregroundColor(.red)
                                        .offset(x: viewModel.waypoints.count > 9 ? 15 : 10, y: -10)
                                }
                            }
                        })
                    }
                }
            }
        }
    }
}

