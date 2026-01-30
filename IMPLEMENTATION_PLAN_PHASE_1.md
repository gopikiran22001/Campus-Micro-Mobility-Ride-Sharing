# Phase 1: Core MVP Implementation Plan

This plan tracks the progress of the Core MVP development.

## 1. Project Setup & Architecture
- [x] Update `pubspec.yaml` with required dependencies (Firebase, State Management, Routing).
- [x] Create project structure (`core`, `features`).
- [x] Configure Theme and Constants.

## 2. Authentication (College Email Only)
- [x] Implement `AuthRepository` with Firebase Auth.
- [x] Implement Email Verification Logic.
- [x] Create Sign-Up Screen (Email/Password).
- [x] Create Login Screen.
- [x] Create Auth State Management (Redirect to Verify/Home).
- [x] **Strict Rule**: Block non-college domains (hardcoded list or regex initially).

## 3. User Profile
- [x] Implement `UserProfile` model.
- [x] Create Profile Setup Screen (Name, Dept, Year, Vehicle).
- [x] Store profile in Firestore (`users` collection).
- [x] **Strict Rule**: Single user role (toggle logic in UI).

## 4. Rider Availability (The "Provider" Mode)
- [x] Add "Accepting Rides" toggle in UI.
- [x] Update status in Firestore.
- [x] Handle geolocation updates (if applicable) or static "available" status.

## 5. Ride Request Flow (The "Student" Mode)
- [x] Create Ride Request Screen (Select Destination).
- [x] Implement "Find Riders" logic (Query Firestore for available riders).
- [x] Display list/map of separate riders.
- [x] Implement "Request Ride" action.

## 6. Ride Lifecycle & State Management
- [x] Implement `Ride` model (Requester, Provider, Status, Timestamps).
- [x] Handle States: `requested` -> `matched` -> `active` -> `completed` / `cancelled`.
- [x] Implement Real-time updates (StreamSubscription).
- [x] **Strict Rule**: 2-minute timeout logic for acceptance.

## 7. Notifications (In-App)
- [x] Listen to Ride changes and show Snackbars/Dialogs. (Handled via Stream UI)
- [x] Show "New Ride Request" to Rider. (Implemented in Rider Dashboard)
- [x] Show "Ride Accepted" to Student. (Implemented in Active Ride View)

## 8. Security Rules
- [ ] Define Firestore rules (conceptual or file).
- [x] Ensure data isolation (Campus ID check).

**Phase 1 Complete for Demo.**
