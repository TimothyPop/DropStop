

import SwiftUI


struct WayPointsListView: View {
    
    @StateObject var viewModel: RouteViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            if viewModel.waypoints.isEmpty {
                VStack {
                    Image(systemName: "map")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    Text("No Drop Offs")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    ForEach(Array(viewModel.waypoints.enumerated()), id: \.element) { index, waypoint in
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.blue)
                                .font(.title)
                                .padding()
                            
                            Text("\(index + 1). \(waypoint)")
                                .font(.system(size: 16))
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(UIColor.systemGray5))
                                .cornerRadius(8)
                                .padding(.vertical, 4)
                            
                            Spacer()
                            
                            Button(action: {
                                if let idx = viewModel.waypoints.firstIndex(of: waypoint) {
                                    viewModel.removeWaypoint(at: idx)
                                    
                                    if viewModel.route != nil {
                                        viewModel.fetchRoute()
                                    }
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            // Navigate back
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Drop Offs")
            }
        })
    }
}
