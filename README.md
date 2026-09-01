# alejandro-advmobprogAY2627

## Lab Activity 3: Discussion

### 1. Interaction of the Cart Model, Services, and Screen
In Lab Activity 3, the architecture follows a reactive and structured data-flow model utilizing **Provider** for state management:
* **The Cart Model (`cart.dart` & `product_model.dart`)**: Defines the core data structures and JSON serialization mapping (`fromJson` and `toJson`) for products and cart items coming from the API.
* **The Services (`cart_service.dart` & `product_service.dart`)**: Handle the HTTP communication layer with the DummyJSON API endpoints. They execute GET and POST requests, fetch raw JSON payloads, decode them, and convert them into robust Dart objects.
* **The Cart & Screen Components**: The service feeds data to the state provider, which notifies the UI screens. When a user interacts with a product card, the state or parameters pass smoothly to the detail screen (`product_details_screen.dart` / `detail_screen.dart`), rendering individual item details dynamically using asynchronous builders (`FutureBuilder`).

### 2. Updated Design Pattern
This activity implements a clean **MVVM (Model-View-ViewModel / Provider Pattern)** architecture:
* **Model**: Manages data structures and business logic representation.
* **View (UI)**: Stateless and Stateful screens (`HomeScreen`, `ProductScreen`, `CartScreen`, and detail views) that passively listen to state updates.
* **ViewModel / Provider (`cart_provider.dart` & `theme_provider.dart`)**: Acts as the intermediary, holding application state, processing user actions (like adding items or toggling themes), and triggering UI rebuilds efficiently without tightly coupling views to services.

### 3. Using `getById` at the Cart Endpoint
To fetch specific records or target individual cart items via the API endpoint using a `getById` approach:
* An HTTP GET request is structured by appending the unique identifier parameter directly to the endpoint URL (e.g., base endpoint combined with `/carts/{id}` or specific item IDs).
* The `CartService` captures this specific route, executes the asynchronous request, and parses the singular JSON response object back into the application.
* This allows the app to fetch precise, targeted data for individual carts or products rather than loading mass collections every time a detail view is triggered.
