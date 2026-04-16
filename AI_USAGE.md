# AI Usage Documentation

This document outlines the usage of AI-powered development tools during the creation of the Smart Geo-Landmarks application for the CSE 489 Mid-Assessment. It serves to fulfill the "Proper AI usage" (20 points) grading criteria.

## 1. AI Assistant Used
* **Tool:** Gemini / Agentic AI Coding Assistant integrated via VS Code.
* **Role:** Pair-programmer, architectural sounding board, and advanced debugging consultant.

## 2. Core Areas of AI Assistance

### A. Architectural Planning & State Management
Instead of writing all logic into the UI layer, AI was used to plan out a structured, maintainable architecture. 
* **Provider Pattern:** AI recommended and helped scaffold the `Provider` state management pattern (`LandmarkProvider`) to cleanly decouple UI files from API and Database logic.
* **Offline-First Synchronization:** AI assisted in designing the `VisitQueue` model and `DatabaseHelper` flow, ensuring actions (visiting/adding landmarks) taken offline are saved to a local SQLite database and synchronized to the REST API once the internet connection is restored.

### B. Complex Logic & Computations
Some of the more mathematically or procedurally complex components were generated with AI assistance, after which the code was reviewed and adapted into the project:
* **Geolocation & Distance:** Utilizing AI to properly implement the `geolocator` and `latlong2` packages to calculate distances in meters between the user's current GPS coordinates and the target landmark.
* **Dynamic UI Rendering:** Implementing the logic requirement that dynamically changes `flutter_map` marker colors conditionally (Red, Orange, Yellow, Green) based on each landmark's fetched score.

### C. Advanced Debugging & Environment Setup
Flutter environment setups often throw platform-specific errors. The AI was heavily utilized to diagnose and resolve these quickly so feature development could continue:
* **Gradle Out of Memory (OOM) Errors:** The AI diagnosed a JVM heap space JVM issue and provided the exact configuration needed in `gradle.properties` (`org.gradle.jvmargs=-Xmx4G`) to allow the build to complete.
* **Build Dependency Paths:** Fixing package caching collisions ("different roots" errors) during deployment to a physical Android device.

## 3. Human-in-the-Loop Implementation
While AI generated code snippets and configuration fixes, the implementation was a strictly iterative "Human-in-the-Loop" process:
1. **Iterative Prompting:** Prompts were written incrementally (e.g., asking first for the SQLite database setup, then later asking to build the synchronization queue logic).
2. **API Verification:** AI-generated API services were manually reviewed and adjusted to ensure they perfectly matched the specific constraints and endpoints of the provided CSE489 REST API.
3. **Refactoring:** Generated code was frequently split and refactored into the appropriate architectural folders (`lib/screens/`, `lib/models/`, `lib/providers/`, `lib/services/`) to adhere to Flutter best practices.

**Summary:** AI was treated as a senior technical consultant to assist with architectural decisions, resolve deep-level environment bugs, and accelerate boilerplate generation. All logic was reviewed, manually tested, and integrated by the developer to ensure project requirements were met.
