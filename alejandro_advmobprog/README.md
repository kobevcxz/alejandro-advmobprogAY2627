## Lab Activity 4: Discussion

### 1. Interaction of the User Model, Service, and Screens

The `user.dart` model represents the user data received from the DummyJSON authentication API. It contains the user's ID, username, email, first name, last name, gender, profile image, access token, and refresh token.

The `user_service.dart` handles the authentication process. It sends the username and password to the `/auth/login` endpoint, converts the API response into a `User` object, and saves the user data locally using `SharedPreferences`.

The `signin_screen.dart` collects the user's credentials and calls the login method from `UserService`. After a successful login, the authenticated user is passed to `HomeScreen`. The `profile_screen.dart` then uses the `User` model to display the user's name, username, email, gender, profile image, and user ID.

The `splash_screen.dart` checks if saved user data and an access token are available. If a saved session exists, the user is automatically redirected to the Home screen. Otherwise, the user is redirected to the Sign-In screen.

### 2. Updated Design Pattern

Lab Activity 4 continues to use an organized Model, Service, Provider, and Screen design pattern.

- **Model:** The `user.dart`, `cart.dart`, and `product_model.dart` files define the structure of the data used by the application.
- **Service:** The `user_service.dart`, `cart_service.dart`, and `product_service.dart` files communicate with the DummyJSON API and convert the responses into Dart objects.
- **Provider:** The `cart_provider.dart` manages the cart state and notifies the interface whenever the cart data changes.
- **Screen:** The splash, sign-in, home, product, cart, profile, and settings screens display the data and handle user interactions.
- **Local Storage:** `SharedPreferences` stores the authenticated user's information so the session remains active after the application is restarted.

This design keeps the API requests, data models, state management, and user interface separated, making the project easier to understand and maintain.

### 3. Rendering the Cart Using the Saved User ID

After a successful login, the user's information is saved using `SharedPreferences`. The saved data includes the user's unique ID.

When `HomeScreen` opens, it passes the authenticated user's ID to `CartProvider` through the `setUserId()` method. The provider then calls `getCartByUserId()` from `CartService`.

The service sends a GET request using the following endpoint:

`/carts/user/{userId}`

Because the endpoint uses the saved user ID, the Cart screen displays only the cart associated with the currently authenticated user instead of using a hardcoded ID. When another user signs in, the provider updates the user ID and loads the correct cart.

### 4. Persistent Authentication and Logout

The application uses `SharedPreferences` to maintain the user's login session. When the application starts, the Splash screen checks if an authenticated user and access token are saved. A valid saved session redirects the user to Home, while a missing session redirects the user to Sign In.

When the user presses the Log Out button on the Profile screen, the saved user data is removed. The application then returns to the Sign-In screen, and the user must authenticate again.