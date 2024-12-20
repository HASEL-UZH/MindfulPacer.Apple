<p align="center">
<img src = "https://img.shields.io/badge/Swift-FA7343?style=for-the-badge&logo=swift&logoColor=white">
<img src = "https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=Xcode&logoColor=white">
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0" />
    <img src="https://img.shields.io/badge/iOS-18.0-pink.svg" alt="iOS 18.0" />
    <img src="https://img.shields.io/badge/WatchOS-11.0-blue.svg" alt="WatchOS 11.0" />
</p>

# Contents

1. [Architecture Overview](#architecture-overview)
    - [Application Layer](#application-layer)
    - [Common UI](#common-ui)
    - [Extensions](#extensions)
    - [Models](#models)
    - [Services](#services)
    - [Repositories](#repositories)
    - [Use Cases](#use-cases)
    - [Scenes](#scenes)
    - [Navigation and Presentation Management](#navigation-and-presentation-management)
2. [Dependency Injection](#dependency-injection)
    - [Benefits of Dependency Injection](#benefits-of-dependency-injection)
    - [Implementation in the Project](#implementation-in-the-project)
3. [Project Structure](#project-structure)
    - [🍏 Shared](#shared)
    - [📱 iOS](#ios)
    - [⌚️ WatchOS](#watchos)
4. [Benefits of This Structure](#benefits-of-this-structure)
5. [Best Practices for Structuring SwiftUI Views](#best-practices-for-structuring-swiftui-views)

# Architecture Overview

This project follows a clean architecture approach combined with MVVM (Model-View-ViewModel) principles. The architecture is designed to ensure a clear separation of concerns, making the codebase scalable, maintainable, and testable. Below is an in-depth explanation of each aspect of the architecture.

## Application Layer

The Application Layer serves as the entry point of the application. It contains the `App` struct which sets up the main views and initializes dependencies. This layer is responsible for:

- **Configuring the Environment**: Setting up the environment and configurations necessary for the application to run.
- **Dependency Injection**: Ensuring all components are properly instantiated and dependencies are injected, typically through a dependency injection framework.

## Common UI

The Common UI layer includes reusable UI components, styles, and view modifiers. This layer is designed to promote reusability and consistency across the application. It consists of:

- **Formatters**: Utilities for formatting data (e.g., dates, numbers) in a standardized way. They ensure that data is presented consistently throughout the app.
- **Styling**: Common styles for UI components such as buttons, colors, and typography. This ensures a consistent look and feel across the app.
- **View Modifiers**: Custom view modifiers encapsulate view modifications, enhancing code readability and reusability. They allow for the application of consistent modifications across different views.
- **Views**: Reusable views that can be used across different scenes. These views are designed to be flexible and adaptable, providing a consistent UI throughout the app.

## Extensions

Extensions are used to extend the functionality of standard library types or custom types. This layer contains utility methods that enhance existing classes without modifying their original implementation. They provide additional methods or properties that are commonly used across the application.

## Models

The Models layer includes the data structures used within the application. It is divided into two main categories:

- **Core Models**: The primary data structures representing the entities within the application, implemented using SwiftData. These models are used throughout the app to represent the main data objects and are designed to seamlessly integrate with SwiftData's features like persistence, querying, and relationships.
- **DTOs (Data Transfer Objects)**: Structures for network responses or other external data formats. DTOs are used to transfer data between the application and external services, ensuring that data is correctly formatted and parsed.

## Services

Services encapsulate the business logic and handle interactions with external systems. They are responsible for:

- **Business Logic**: Encapsulating core business rules and operations that transform data. Services ensure that the business rules are consistently applied across the application.
- **Networking**: Managing network calls to fetch or send data to remote servers. Services handle the details of making HTTP requests and processing responses.
- **External Integrations**: Handling integrations with external systems like authentication providers, payment gateways, or cloud services. Services manage the complexities of interacting with these systems.
- **Task Execution**: Performing specific tasks such as data fetching, authentication, or cloud operations. Services execute the necessary steps to complete these tasks and handle any errors that may occur.

A service can be defined as follows:

```swift
protocol MyServiceProtocol {
    func myFunction()
}

class MyService: MyServiceProtocol {
    func myFunction() {
        // Implementation
    }
}
```

## Repositories

Repositories act as an abstraction layer over data sources. They are responsible for:

- **Data Abstraction**: Providing a clean API for accessing data from various sources (e.g., databases, APIs). Repositories hide the details of data access, making it easier to manage and test.
- **Combining Data Sources**: Aggregating data from multiple sources and presenting it as a unified model. Repositories can combine data from local databases and remote APIs to provide a comprehensive data set.
- **Data Mapping**: Converting raw data (e.g., JSON responses) into domain models used by the application. Repositories handle the transformation of data into a format that the application can use.
- **Caching and Persistence**: Handling local data caching to improve performance and reduce network calls. Repositories can cache data locally and manage persistence to ensure data is available even when offline.

A repository can be defined as follows:

```swift
protocol MyRepository {
    funch fetchItems(query: String) -> [Items]
}

class DefaultMyRepository: MyRepository {
    private let myAPI: MyAPI
    
    init(myAPI: MyAPI) {
        self.myAPI = myAPI
    }
    
    func fetchItems(query: String) -> [Items] {
        // Implementation
    }
}
```

## Use Cases

Use Cases represent specific actions or tasks that the application can perform. They encapsulate the business logic, orchestrating interactions between repositories and services. Each use case is a self-contained unit of work that defines a single operation or process. They are responsible for:

- **Executing Business Logic**: Use cases contain the specific business rules and logic for a particular task or operation.
- **Interacting with Repositories and Services**: Use cases coordinate the interactions between repositories and services to complete the task.
- **Providing a Clear API**: Use cases offer a clear and simple API for the rest of the application to perform specific actions.
- **Error Handling**: Use cases handle errors that occur during the execution of business logic. They ensure that errors are properly managed and communicated to the calling components, typically the ViewModels.

A use case can be defined as follows:

```swift

protocol MyUseCase {
    func execute()
}

class DefaultMyUseCase: MyUseCase {
    func execute() {
        // Implementation
    }
}
```

## Scenes

Scenes correspond to the different screens or views in the application, following the MVVM pattern. Each scene consists of:

- **View**: The SwiftUI view that defines the UI elements and layout. Views are responsible for presenting data to the user and handling user interactions.
- **ViewModel**: The logic that binds the view to the use cases, handling user inputs and updating the UI state. ViewModels manage the data flow between the view and the rest of the application.

A view model can have the following structure:

```swift
@Observable
class YourViewModelName {

    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let someUseCase: SomeUseCase
    // Add other use cases or services as needed.

    // MARK: - Published Properties (State)
    
    var someStateVariable: SomeType = initialValue
    // Add other state variables that the view observes.

    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        someUseCase: SomeUseCase,
        // Inject other dependencies here.
    ) {
        self.modelContext = modelContext
        self.someUseCase = someUseCase
        // Initialize other dependencies.
        
        setupBindings()
        // Perform additional setup if necessary.
    }

    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Set up any Combine publishers, data bindings, etc.
    }
    
    // MARK: - View Lifecycle
    
    func onViewAppear() {
        // Actions to perform when the view appears, like triggering use cases.
        performInitialSetup()
    }
    
    func onViewDisappear() {
        // Actions to perform when the view disappears.
    }

    // MARK: - User Actions
    
    func didTapSomeButton() {
        // Handle button tap, possibly triggering a use case.
        performSomeAction()
    }
    
    func didSelectItem(_ item: ItemType) {
        // Handle item selection, possibly updating state or triggering a use case.
        selectItem(item)
    }

    // MARK: - Private Methods
    
    private func performInitialSetup() {
        // Example: Initial setup logic, possibly data fetching or state initialization.
    }
    
    private func performSomeAction() {
        // Example: Logic to perform an action, like calling a use case and updating state.
    }
    
    private func selectItem(_ item: ItemType) {
        // Example: Logic to handle item selection and update state.
        selectedCategory = item
    }

    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        // Handle errors, possibly updating an error state or showing an alert.
        // Example:
        // self.errorMessage = error.localizedDescription
    }

    // MARK: - Deinitialization
    
    deinit {
        // Clean up resources if necessary.
    }
}
```

## Navigation and Presentation Management

This project follows a consistent, extensible approach to managing navigation, sheets, and alerts within SwiftUI views. The pattern leverages enums and SwiftUI's state-driven architecture to keep the code clean, modular, and easy to maintain.

### Navigation

Navigation is handled using a `NavigationStack` in combination with an enum that represents different destinations within a view. Each view defines its own enum for navigation destinations. This enum ensures type safety and makes it easy to navigate between different screens without relying on string identifiers.

Example:

```swift
enum MyViewNavigationDestination: Hashable {
    case firstDestination
    case secondDestination(SomeModel?)
}
```

This enum is used within the view to manage navigation destinations. The destinations are linked using `.navigationDestination`, ensuring that SwiftUI knows where to navigate based on the value of the enum.

Usage:

```swift
.navigationDestination(for: MyViewNavigationDestination.self) { destination in
	navigationDestination(for: destination)
}

@ViewBuilder
private func navigationDestination(for destination: MyViewNavigationDestination.self) -> some View {
	switch destination {
	case . firstDestination:
		FirstView()
	case .secondDestination(let model):
        SecondView(model: model)
	}
}
```

This structure allows the view to navigate based on programmatically set state, ensuring that navigation is both flexible and type-safe.

### Sheets

Sheets are handled similarly to navigation by defining an enum that conforms to Identifiable. This enum specifies the different sheets that can be presented by a view. Each sheet can be presented based on the active state in the ViewModel.

Example:

```swift
enum MyViewSheet: Identifiable {
    case firstSheet
    case secondSheet
    
    var id: Int {
        hashValue
    }
}
```

The ViewModel controls the active sheet, and the view observes this state to present the appropriate sheet using `.sheet`.

Usage:

```swift
.sheet(item: $viewModel.activeSheet) { sheet in
    switch sheet {
    case .firstSheet:
        FirstSheetView()
    case .secondSheet:
        SecondSheetView()
    }
}
```

This pattern allows for easily adding new sheets to a view without modifying much of the existing code. The ViewModel manages which sheet is currently active by setting the `activeSheet` property.

### Alerts

Alerts follow a similar pattern to sheets. An enum representing different alert types is defined, and the view presents an alert based on the active state in the ViewModel.

Example:

```swift
enum MyViewAlert: Identifiable {
    case errorAlert
    case confirmationAlert
    
    var id: Int {
        hashValue
    }
}
```

The ViewModel triggers alerts by setting the activeAlert property, and the view observes this state to display the correct alert using `.alert`.

Usage:

```swift
.alert(item: $viewModel.activeAlert) { alert in
    switch alert {
    case .errorAlert:
        Alert(title: Text("Error"), message: Text("Something went wrong."))
    case .confirmationAlert:
        Alert(
            title: Text("Confirm"),
            message: Text("Are you sure?"),
            primaryButton: .destructive(Text("Yes")),
            secondaryButton: .cancel()
        )
    }
}
```

## Dependency Injection

The architecture uses a dependency injection framework, specifically the `Factory` framework, to manage dependencies and ensure loose coupling between components. Dependency injection is a design pattern that allows for the creation of dependent objects outside of the class that uses them, enabling better modularity and easier testing. Here’s how dependency injection is implemented in the project:

### Benefits of Dependency Injection

- **Easy Testing**: Dependencies can be easily mocked or replaced during testing, making it easier to test individual components in isolation.
- **Flexibility**: Implementations can be swapped without changing the dependent code, allowing for easier maintenance and updates as the application evolves.
- **Decoupling**: Components are loosely coupled, making the codebase more modular and easier to manage. This decoupling is essential for maintaining a clean architecture.

### Implementation in the Project

The project utilizes the `Factory` framework for dependency injection, which allows for the easy management of dependencies and the creation of complex dependency graphs. The `Factory` framework is used in containers that manage and provide instances of use cases and view models throughout the application.

The `UseCasesContainer` is responsible for managing and providing instances of various use cases within the application. Each use case is defined as a `Factory` property, which ensures that the required dependencies are provided automatically when the use case is instantiated.

The `ScenesContainer` is used to manage the dependencies for the view models associated with different scenes in the application. Similar to the `UseCasesContainer`, each view model is defined as a `Factory` property, which ensures that the required use cases are injected into the view model when it is instantiated.

By leveraging the `Factory` framework, this project adheres to the principles of dependency injection, which enhances the modularity, testability, and maintainability of the codebase. Each component's dependencies are clearly defined and managed, allowing for a flexible and scalable architecture that can easily adapt to changes and new requirements.

# Project Structure

This project follows a clean architecture approach combined with MVVM principles. The structure is designed to ensure a clear separation of concerns, making the codebase scalable, maintainable, and testable. 

```plaintext
MindfulPacer
├── Shared
│   ├── Common UI
│   ├── Errors
│   ├── Extensions
│   ├── Models
│   ├── Resources
├── iOS
│   ├── Application
│   ├── Common UI
│   ├── Data
│   ├── Extensions
│   ├── Preview Content
│   ├── Resources
│   ├── Scenes
│   ├── Services
│   └── Use Cases
├── WatchOS
│   ├── Application
│   ├── Common UI
│   ├── Extensions
│   ├── Preview Content
│   ├── Resources
│   ├── Scenes
│   ├── Services
│   └── Use Cases
├── iOSTests
│   ├── Mocks
│   ├── Services Tests
│   ├── View Models Tests
│   ├── Use Cases Tests
│   ├── Utilities Tests
└── WatchOSTests
    ├── Mocks
    ├── Services Tests
    ├── View Models Tests
    ├── Use Cases Tests
    └── Utilities Tests
```

## 🍏 Shared

Contains components that are shared between iOS and WatchOS.

- **Common UI**: UI components and styles that are used by both iOS and WatchOS.
- **Data**: Shared data handling components.
- **Errors**: Contains error types and handling mechanisms that are used across both iOS and WatchOS.
- **Models**: Data models used across both iOS and WatchOS apps.
- **Resources**: Assets and resources use across both iOS and WatchOS apps.

## 📱 iOS

Contains iOS-specific components and configurations.

- **Application**: Entry point and main configuration for the iOS app.
- **Common UI**: UI components and styles specific to iOS.
- **Extensions**: iOS-specific extensions.
- **Preview Content**: Provides mock data and configurations used for SwiftUI previews on iOS.
- **Resources**: Assets and resources specific to the iOS app.
- **Scenes**: Views and view models specific to iOS.
- **Services**: iOS-specific services.
- **Use Cases**: Business logic specific to iOS.

## ⌚️ WatchOS

Contains WatchOS-specific components and configurations.

- **Application**: Entry point and main configuration for the WatchOS app.
- **Common UI**: UI components and styles specific to WatchOS.
- **Extensions**: WatchOS-specific extensions.
- **Preview Content**: Provides mock data and configurations used for SwiftUI previews on WatchOS.
- **Resources**: Assets and resources specific to the WatchOS app.
- **Scenes**: Views and view models specific to WatchOS.
- **Services**: WatchOS-specific services.
- **Use Cases**: Business logic specific to WatchOS.

## Benefits of This Structure

- **Reusability**: Shared code can be reused across both platforms, reducing duplication and ensuring consistency.
- **Maintainability**: A clear separation of concerns makes the codebase easier to manage and maintain.
- **Scalability**: This structure can easily accommodate new features and components as the app grows.

## Best Practices for Structuring SwiftUI Views

When structuring SwiftUI views, it's important to focus on clarity, readability, and reusability. By following certain conventions and keeping code organized, you can ensure a clean, maintainable project structure. Below are best practices for structuring your SwiftUI views, along with a skeleton structure for reference.

### 1. Naming Conventions

- **Consistency**: Name your views without the `View` suffix, following SwiftUI's convention (e.g., `Button` instead of `ButtonView`).
- **Clarity**: Use descriptive names that clearly convey the intent of the view. For example, prefer `submitButton` over something generic like `button1`.

### 2. Logical Grouping with `MARK`

- **Properties**: Group properties like state variables, bindings, and other dependencies at the top under `// MARK: Properties`.
- **Body**: The main body of the view should be defined under `// MARK: - Body`.
- **Private Subviews**: Use `@ViewBuilder` or private `var` declarations for subviews, keeping related subviews grouped and consistently named under appropriate `MARK` labels, like `// MARK: Header`, `// MARK: Buttons`, etc. Use `// MARK:` rather than `// MARK: -` for anything inside the actual view.

### 3. Use of `@ViewBuilder`

- For complex or reusable subviews, define them using `@ViewBuilder` to enhance readability and promote modularity.
- Name these builder methods descriptively, such as `header`, `footer`, `actionButton`, to clarify their role within the view.

### 4. Order of Modifiers

When applying modifiers in SwiftUI, use a logical order for better readability and maintainability:
1. **Basic View Modifiers**: `frame`, `padding`, `background`.
2. **Content Modifiers**: `font`, `foregroundColor`, `multilineTextAlignment`.
3. **Layout Modifiers**: `alignment`, `padding`, `frame`.
4. **Style Modifiers**: `background`, `cornerRadius`, `shadow`.
5. **State/Behavior Modifiers**: `onTapGesture`, `onAppear`, `animation`.
6. **Accessibility Modifiers**: `accessibilityLabel`, `accessibilityHint`.
7. **Environment Modifiers**: `environmentObject`, `environment`.

### 5. Avoid Overloading the `body` Property

Avoid packing too much code into the main `body` property of your view. Break down subviews into smaller private views or `@ViewBuilder` functions to keep the `body` clean and focused.

### 6. Use of Previews

Ensure that each view has a SwiftUI preview for testing and visualizing the UI. Use sample data or view models to provide meaningful content for the preview.

### Skeleton Structure for SwiftUI Views

```swift
import SwiftUI

// MARK: - ExampleView

struct ExampleView: View {
    // MARK: Properties
    
    @Bindable var viewModel: ExampleViewModel

    // MARK: Body

    var body: some View {
        VStack {
            header
            itemsList
            actionButton
        }
        .padding()
        .navigationTitle("Example View")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
            }
        }
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        HStack {
            Text("Welcome, \(viewModel.userName)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical)
    }

    // MARK: Items List

    @ViewBuilder
    private var itemsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.items, id: \.id) { item in
                    itemRow(for: item)
                }
            }
        }
    }

    // MARK: Action Button

    @ViewBuilder
    private var actionButton: some View {
        Button(action: viewModel.didTapSubmit) {
            Text("Submit")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    // MARK: Item Row

    @ViewBuilder
    private func itemRow(for item: Item) -> some View {
        HStack {
            Text(item.name)
                .font(.headline)
            Spacer()
            Text(item.value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: Navigation Buttons

    private var backButton: some View {
        Button(action: viewModel.didTapBack) {
            Image(systemName: "arrow.left")
        }
    }

    private var settingsButton: some View {
        Button(action: viewModel.didTapSettings) {
            Image(systemName: "gearshape.fill")
        }
    }
}

// MARK: - Preview

#Preview {
    static var previews: some View {
        ExampleView(viewModel: ExampleViewModel())
    }
}