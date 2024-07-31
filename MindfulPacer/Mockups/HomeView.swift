//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.07.2024.
//

import SwiftUI
import Charts

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [GridItem(spacing: 16), GridItem(spacing: 16)], spacing: 16) {
                        widget1
                        widget2
                    }
                    widget3
                    widget4
                    widget5
                }
                .padding([.horizontal, .bottom])
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .onAppear {
                HealthKitService.shared.fetchHeartRateData(for: .month) { result in
                    switch result {
                    case .success(let success):
                        success.forEach { sample in
                            print("DEBUGY:", sample.description)
                        }
                    case .failure(let failure):
                        print("DEBUGY: Error")
                    }
                }
            }
        }
    }
    
    var widget1: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                    Text("Steps")
                    Spacer()
                    Menu {
                        Button {
                        
                        } label: {
                            Label("Hide Widget", systemImage: "eye.slash.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("9,870")
                        .font(.title.bold())
                    Text("steps")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
    
    var widget2: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                    Text("Events")
                    Spacer()
                    Menu {
                        Button {
                        
                        } label: {
                            Label("Hide Widget", systemImage: "eye.slash.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("12")
                        .font(.title.bold())
                    Text("events")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
    
    var widget3: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Threshold Exceeded")
                    Spacer()
                    Menu {
                        Button {
                        
                        } label: {
                            Label("Hide Widget", systemImage: "eye.slash.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                
                Text("Here is a summary different alarms triggered today.")
                    .font(.body.weight(.semibold))
                
                Divider()
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Light")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.yellow)
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("5")
                                .font(.title.bold())
                            Text("alarms")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                                        
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Medium")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.orange)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("3")
                                .font(.title.bold())
                            Text("alarms")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strong")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("4")
                                .font(.title.bold())
                            Text("alarms")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
    
    var widget4: some View {
        NavigationLink {
            
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "waveform.path.ecg")
                    Text("Heart Rate")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color(.systemGray3))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                
                HeartRateChart()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
            .buttonStyle(.plain)
        }
    }
    
    var widget5: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                HStack(spacing: 4) {
                    Text("Self-Reports / Events / Diary Entries")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.tint)
            
            Text("Here is a summary of the events triggered today.")
                .font(.body.weight(.semibold))
            
            Divider()
            
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: "figure.walk")
                        .resizable()
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(Color("PrimaryGreen").opacity(0.1))
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Walking")
                            .foregroundStyle(Color.secondary)
                            .font(.footnote.weight(.semibold))
                        
                        Label("HR above 100", systemImage: "arrow.up.heart.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Text(Date.now.formatted(.dateTime.hour().minute()))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    Image(systemName: "figure.stairs")
                        .resizable()
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(Color("PrimaryGreen").opacity(0.1))
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Climbing Stairs")
                            .foregroundStyle(Color.secondary)
                            .font(.footnote.weight(.semibold))
                        Label("HR above 100", systemImage: "arrow.up.heart.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                                        
                    Spacer()
                    
                    Text(Date.distantPast.formatted(.dateTime.hour().minute()))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    Image(systemName: "shower.fill")
                        .resizable()
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(Color("PrimaryGreen").opacity(0.1))
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Showering")
                            .foregroundStyle(Color.secondary)
                            .font(.footnote.weight(.semibold))
                        Label("HR above 100", systemImage: "arrow.up.heart.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Text(Date.distantFuture.formatted(.dateTime.hour().minute()))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

struct HeartRateChart: View {
    // Example data points (timestamps and heart rates)
    let data: [(time: Date, heartRate: Double)] = {
        let now = Date()
        let interval: TimeInterval = 6 * 60 * 60 // 6 hours
        var readings = [(time: Date, heartRate: Double)]()
        for i in 0..<60 {
            let time = now.addingTimeInterval(-interval + TimeInterval(i * 6 * 60))
            let heartRate = Double.random(in: 60...120) // Random heart rate between 60 and 110
            readings.append((time: time, heartRate: heartRate))
        }
        return readings
    }()
    
    // Example events with SF Symbols
    let events: [(time: Date, symbol: String)] = {
        let now = Date()
        return [
            (now.addingTimeInterval(-4 * 60 * 60), "figure.walk.circle.fill"), // Event 1: 4 hours ago
            (now.addingTimeInterval(-2 * 60 * 60), "tennisball.circle.fill"), // Event 2: 2 hours ago
            (now.addingTimeInterval(-1 * 60 * 60), "figure.stairs.circle.fill")  // Event 3: 1 hour ago
        ]
    }()
    
    var body: some View {
        VStack {
            Chart {
                ForEach(data, id: \.time) { entry in
                    LineMark(
                        x: .value("Time", entry.time),
                        y: .value("Heart Rate", entry.heartRate)
                    )
                }
                
                RuleMark(y: .value("80 bpm", 80))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(Color.yellow)
                
                RuleMark(y: .value("100 bpm", 100))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(Color.red)
            }
            .chartYScale(domain: 60...130)
            .chartYAxis {
                AxisMarks(preset: .extended, position: .leading)
            }
            .overlay {
                GeometryReader { geometry in
                    ForEach(events, id: \.time) { event in
                        if let xPosition = xPosition(for: event.time, in: geometry, data: data) {
                            Image(systemName: event.symbol)
                                .resizable()
                                .scaledToFit()
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 18, height: 18)
                                .foregroundStyle(Color.primary)
                                .position(x: xPosition, y: geometry.size.height - 18)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
    }
    
    private func xPosition(for date: Date, in geometry: GeometryProxy, data: [(time: Date, heartRate: Double)]) -> CGFloat? {
        guard let minTime = data.first?.time, let maxTime = data.last?.time else {
            return nil
        }
        
        let totalTime = maxTime.timeIntervalSince(minTime)
        let eventTime = date.timeIntervalSince(minTime)
        
        let chartWidth = geometry.size.width
        let xPosition = chartWidth * CGFloat(eventTime / totalTime)
        
        return xPosition
    }
}

#Preview {
    TabView {
        HomeView()
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tint(Color("PrimaryGreen"))
    }
}
