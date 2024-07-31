//
//  OnboardingView.swift
//  iOS
//
//  Created by Grigor Dochev on 11.07.2024.
//

import SwiftUI
import HealthKit

struct OnboardingView: View {
    @StateObject private var healthDataManager = HealthDataManager()
    @Environment(\.openURL) private var openURL
    @State private var path: [Int] = []
    @State private var animate = false
    @State private var acceptTicked = false
    
    var body: some View {
        NavigationStack(path: $path) {
            home
                .navigationDestination(for: Int.self) { value in
                    switch value {
                    case 1: appleWatch
                    case 2: notifications
                    case 3: health
                    case 4: tutorialPagePlaceholder
                    case 5: disableActivityPromotingFeatures
                    case 6: disclaimer
                    default: EmptyView()
                    }
                }
        }
    }
    
    var home: some View {
        VStack(spacing: 16) {
            Spacer()
            
            VStack(spacing: 4) {
                Image("MindfulPacer Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top)
                
                Text("MindfulPacer")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("PrimaryGreen"), Color("TertiaryGreen")],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 32) {
                HStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .resizable()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Support for Activity Pacing")
                            .fontWeight(.semibold)
                        Text("Better manage your physical and mental energy, by regulating your activity levels.")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .resizable()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diary on Activities & Energy")
                            .fontWeight(.semibold)
                        Text("Reflect on your activities, energy management, moods and symptoms.")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    Image(systemName: "applewatch")
                        .resizable()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Apple Watch Sync")
                            .fontWeight(.semibold)
                        Text("Amend your diary with biometric data and receive reminders for reflection.")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    Image(systemName: "chart.xyaxis.line")
                        .resizable()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Insights")
                            .fontWeight(.semibold)
                        Text("Learn how your activities impact your energy by visualizing the diary and biometric data on a timeline.")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                path.append(1)
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryGreen"))
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }

    var appleWatch: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Text("Connect to your Apple Watch")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 16) {
                        Image("Apple Watch")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    Text("When pairing MindfulPacer with your Apple Watch, you can visualize your biometric data (including heart rate and steps) and receive reminders on your watch to reflect at times defined by you.\n\nMindfulPacer is automatically installed on your Apple Watch.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "exclamationmark.applewatch")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Can't find MindfulPacer on your Apple Watch?")
                                .fontWeight(.semibold)
                            Text(
                        """
                        1. Once your Apple Watch is connected to your iPhone, open the **Watch** app.
                        2. Go to the **My Watch** tab.
                        3. Scroll down to see **MindfulPacer** and tap **Install**.
                        4. Once you tapped **Install**, make sure the toggle is set to **Show App** on Apple Watch.
                        """
                            )
                            .font(.subheadline)
                            .layoutPriority(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Button {
                path.append(2)
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryGreen"))
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    path.append(2)
                }
                .fontWeight(.semibold)
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    var health: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Text("Connect to Apple Health")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Image("Apple Health Icon Official")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                    
                    Text("MindfulPacer can visualize your biometric data (as measured by your Apple Watch) and visualize it together with your diary entries in the Analysis page.\n\nPlease allow MindfulPacer to access your Apple Health data. Select the biometric data that you want to share (e.g. heart rate and/or steps).")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "info.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .fontWeight(.semibold)
                            Text("You can always change this permission later, by navigating to Settings > Privacy & Security > Health > MindfulPacer.")
                                .font(.subheadline)
                                .layoutPriority(1)
                            Divider()
                            Button {
                                
                            } label: {
                                Text("Open Settings")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("PrimaryGreen"))
                            }
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            
            VStack(spacing: 8) {
                Button {
                    healthDataManager.requestAuthorization()
                    path.append(4)
                } label: {
                    Text("Allow Health Access")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryGreen"))
            }
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    path.append(4)
                }
                .fontWeight(.semibold)
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    var notifications: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Text("Receive Reminders for Reflection")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Image(systemName: "bell.square.fill")
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .frame(width: 128, height: 128)
                    
                    Text("MindfulPacer can remind you to reflect on your activities, energy management, moods and symptoms, for example at specific times or when a biometric value (such as your heart rate or steps) reaches a certain threshold.\n\nPlease allow MindfulPacer to send notifications to receive the reflection reminders.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "info.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .fontWeight(.semibold)
                            Text("You can always change this permission later, by navigating to Settings > Privacy & Security > Notifications > MindfulPacer.")
                                .font(.subheadline)
                                .layoutPriority(1)
                            Divider()
                            Button {
                                
                            } label: {
                                Text("Open Settings")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("PrimaryGreen"))
                            }
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            
            VStack(spacing: 8) {
                Button {
                    healthDataManager.requestNotificationAuthorization()
                    path.append(3)
                } label: {
                    Text("Allow Notifications")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryGreen"))
            }
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    path.append(3)
                }
                .fontWeight(.semibold)
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    var tutorialPagePlaceholder: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Text("Explain Main Features X")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TabView {
                        ForEach(0 ..< 5) { item in
                            Image("iPhone Placeholder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 256, height: 256)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 356)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                                        
                    Text("Above we will put a screenshot of the feature being explained. Here we can put a short description of the feature and explain it a bit.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0...3, id: \.self) { index in
                            HStack(spacing: 16) {
                                Image(systemName: "minus")
                                Text("Point \(index + 1)")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Button {
                path.append(5)
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryGreen"))
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    var disclaimer: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Text("Disclaimer")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "hand.raised.app.fill")
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .frame(width: 128, height: 128)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.yellow)
                            Text("MindfulPacer as well as the Apple Watch are **NOT** medical grade apps and may display inaccurate data.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.yellow)
                            Text("MindfulPacer only processes raw data from your Apple Watch and your diary entries, and does **NOT** make automated recommendations.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.yellow)
                            Text("Do **NOT** solely rely on MindfulPacer for pacing and managing your activities and energy.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("When in doubt, please contact an experienced physician, personal trainer or other qualified professional.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "envelope.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                            .symbolEffect(.bounce, value: animate)
                            .onAppear { animate.toggle() }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You can reach out to the following email address in case you have further questions: mindfulpacer@outlook.com")
                                .tint(Color("PrimaryGreen"))
                            
                            Divider()
                            
                            Button {
                                openURL(URL(string: "https://mindfulpacer.ch/terms-of-use")!)
                            } label: {
                                Text("Learn More")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("PrimaryGreen"))
                            }
                        }
                        .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                                        
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            acceptTicked.toggle()
                        }
                    } label: {
                        Image(systemName: acceptTicked ? "checkmark.circle.fill" : "circle")
                            .font(.title3.weight(.semibold))
                    }
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(Color("PrimaryGreen"))
                    
                    Text("I Understand and Accept")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button {
                    
                } label: {
                    Text("Finish")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .tint(Color("PrimaryGreen"))
                .disabled(!acceptTicked)
            }
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    var disableActivityPromotingFeatures: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Text("Disable Activity Promoting Features")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "square.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color("PrimaryGreen"))
                        .frame(width: 128, height: 128)
                    
                    Text("Apple has many activity-promoting features on the iPhone and Apple Watch. We will guide you through the process of disabling these.")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "figure.stand")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Disabling Stand Reminders")
                                .fontWeight(.semibold)
                            
                            Group {
                                Text("1. Open the Watch app on your iPhone.")
                                Text("2. Tap on 'My Watch' at the bottom.")
                                Text("3. Scroll down and tap on 'Activity'.")
                                Text("4. Toggle off 'Stand Reminders'.")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "bell.badge.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Disabling Activity Reminders")
                                .fontWeight(.semibold)
                            
                            Group {
                                Text("1. Open the Watch app on your iPhone.")
                                Text("2. Tap on 'My Watch'.")
                                Text("3. Tap on 'Notifications'.")
                                Text("4. Select 'Activity'.")
                                Text("5. Toggle off 'Activity Reminders'.")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "figure.pool.swim")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Disabling Exercise Notifications")
                                .fontWeight(.semibold)
                            
                            Group {
                                Text("1. Open the Watch app on your iPhone.")
                                Text("2. Tap on 'My Watch'.")
                                Text("3. Tap on 'Notifications'.")
                                Text("4. Select 'Activity'.")
                                Text("5. Toggle off 'Workout Reminders'.")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "figure.walk")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adjust Move Goals")
                                .fontWeight(.semibold)
                            
                            Group {
                                Text("1. Open the Activity app on your Apple Watch.")
                                Text("2. Firmly press the display.")
                                Text("3. Tap 'Change Move Goal'.")
                                Text("4. Adjust the goal to a level that suits your current capabilities.")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                    
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "aqi.low")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color("PrimaryGreen"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Disabling Breathe Reminders")
                                .fontWeight(.semibold)
                            
                            Group {
                                Text("1. Open the Watch app on your iPhone.")
                                Text("2. Tap on 'My Watch'.")
                                Text("3. Tap on 'Breathe'.")
                                Text("4. Toggle off 'Breathe Reminders'.")
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                                        
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            Button {
                path.append(6)
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)
            .tint(Color("PrimaryGreen"))
            .padding([.horizontal, .top])
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .background {
            Color(.secondarySystemGroupedBackground)
                .ignoresSafeArea()
        }
    }
}

class HealthDataManager: ObservableObject {
    private var healthStore = HKHealthStore()
    @Published var heartRate: Double = 0.0
    @Published var stepCount: Double = 0.0
    
    init() {}
    
    func requestAuthorization() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let typesToRead: Set = [heartRateType, stepCountType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if !success {
                // Handle the error here.
                print("Authorization failed: \(String(describing: error))")
            }
        }
    }
    
    func requestNotificationAuthorization() {
         let center = UNUserNotificationCenter.current()
         center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
             if let error = error {
                 print("Notification authorization failed: \(error.localizedDescription)")
                 return
             }
         }
     }
}


#Preview {
    OnboardingView()
        .tint(Color("PrimaryGreen"))
}
