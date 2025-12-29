//
//  ContentView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FlowerViewModel()
    @State private var showGarden = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading flower...")
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state (F-001 requirement)
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            viewModel.loadCurrentFlower()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let flower = viewModel.currentFlower {
                    // Main flower display (F-001)
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // Flower Image
                        Image(flower.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .onTapGesture {
                                // Will navigate to Flower Care Screen (S-002) in B-002
                            }
                        
                        // Flower Name
                        Text(flower.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Partner Status (F-004 placeholder)
                        HStack(spacing: 12) {
                            Image(systemName: partnerStatusIcon)
                                .foregroundColor(partnerStatusColor)
                            Text(partnerStatusText)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // Streak Count (F-005 placeholder)
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(viewModel.streakCount) day streak")
                                .font(.headline)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        // Garden Dropdown Button (F-007)
                        Button(action: {
                            showGarden.toggle()
                        }) {
                            HStack {
                                Text("Garden")
                                Image(systemName: "chevron.down")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Flower Care")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showGarden) {
                GardenView()
            }
        }
        .onAppear {
            // Set model context and load flower (F-001: loads on app open)
            if viewModel.modelContext == nil {
                viewModel.modelContext = modelContext
            }
            viewModel.loadCurrentFlower()
        }
    }
    
    // Partner status helpers
    private var partnerStatusIcon: String {
        switch viewModel.partnerStatus {
        case .completed:
            return "checkmark.circle.fill"
        case .waiting:
            return "clock.fill"
        case .notConnected:
            return "person.crop.circle.badge.questionmark"
        }
    }
    
    private var partnerStatusColor: Color {
        switch viewModel.partnerStatus {
        case .completed:
            return .green
        case .waiting:
            return .orange
        case .notConnected:
            return .gray
        }
    }
    
    private var partnerStatusText: String {
        switch viewModel.partnerStatus {
        case .completed:
            return "Partner completed today's care"
        case .waiting:
            return "Waiting for partner"
        case .notConnected:
            return "Partner not connected"
        }
    }
}

// Placeholder Garden View (will be fully implemented in B-007)
struct GardenView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Your Garden")
                    .font(.title)
                    .padding()
                Text("No flowers yet")
                    .foregroundColor(.gray)
                    .padding()
            }
            .navigationTitle("Garden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss handled by sheet
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
