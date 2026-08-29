//
//  WatchChartsView.swift
//  TapCounterWatch
//
//  Reached with a right swipe from the counter list (see WatchContentView).
//  Will chart button's tap history.
//

import SwiftUI

struct WatchChartsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Charts Coming Soon")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Work in progress")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Charts")
        }
    }
}

#Preview {
    WatchChartsView()
}
