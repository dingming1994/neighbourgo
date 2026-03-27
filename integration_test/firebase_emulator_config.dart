/// Firebase Emulator host and port constants.
///
/// These must match the ports defined in `firebase.json` at the project root.
library;

const String emulatorHost = 'localhost';

// Auth emulator
const int authEmulatorPort = 9099;

// Firestore emulator
const int firestoreEmulatorPort = 8080;

// Storage emulator
const int storageEmulatorPort = 9199;

// Cloud Functions emulator
const int functionsEmulatorPort = 5001;

// Emulator UI
const int emulatorUiPort = 4000;
