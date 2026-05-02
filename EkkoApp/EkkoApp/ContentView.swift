//
//  ContentView.swift
//  EkkoApp
//
//  Created by Guilherme Palma on 02/05/26.
//

import SwiftUI
import EkkoCore

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Ekko \(EkkoVersion.current)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
