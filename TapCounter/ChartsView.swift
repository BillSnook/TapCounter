//
//  ChartsView.swift
//  TapCounter
//
//  The "Charts" tab -- will chart each button's tap history (from
//  TapEvents) by day/time. Placeholder for now.
//

import SwiftUI

struct ChartsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Charts Coming Soon",
                systemImage: "chart.bar.xaxis",
                description: Text("Work in progress — this will chart each button's tap history.")
            )
            .navigationTitle("Charts")
        }
    }
}

#Preview {
    ChartsView()
}
