//
//  ContentView.swift
//  ViewWithMetal
//
//  Created by Itsuki on 2025/09/15.
//

import SwiftUI
import MetalKit
import Metal

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Basic")
                        .font(.headline)
                    
                    BasicMetalView()
                    
                    Divider()
                    
                    Text("With Animation + Control")
                        .font(.headline)
                    
                    AnimateMetalView()
                }
                .padding()
                .scrollTargetLayout()
            }
            .navigationTitle("View With Metal 4")

        }
    }
}

#Preview {
    ContentView()
}
