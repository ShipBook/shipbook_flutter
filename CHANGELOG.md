## 1.1.0

* Added `Shipbook.getSessionHeaders()`. Add its headers to requests toward your own backend, and the Shipbook console links this app session to the sessions those requests create in your Node.js backend. It returns an empty map until login completes, so spreading it is always safe.
* Fixed login failing when the cached config was left corrupt, for example by a crash mid-write. The SDK now discards it and falls back to the default config.

## 1.0.0

* Initial stable release
* Remote logging with configurable severity levels
* Automatic uncaught exception and Flutter error capture
* User identification and session tracking
* Screen tracking
* Offline log queuing
* Dynamic remote configuration

## 0.0.1

* Initial development release
