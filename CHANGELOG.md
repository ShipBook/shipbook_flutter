## 2.0.1

* Fixed apps on Windows, macOS, Linux and web never connecting to Shipbook. The SDK sent no device ID on those platforms, so the server turned the login down. On web, the SDK stopped before it even tried to log in. The SDK now reads the device ID on every platform. Where there is none, it creates a random ID and keeps it on the device.
* If reading the device or app info fails, the SDK now logs a warning and logs in anyway, instead of waiting forever.

## 2.0.0

* Upgrade to get an SDK that follows the Shipbook server: it stops sending when the server refuses your app or is busy, and calling `Shipbook.start` again costs nothing.
* The SDK obeys the server. If the server refuses the app (an unknown app ID, or traffic far past fair use), the SDK pauses: it sends nothing and drops new logs until the pause ends, at most 30 days and across restarts. If the server or a proxy answers busy (429 or 503), it waits (the `Retry-After` time, 5 minutes without one, at most an hour) and sends the saved logs afterwards. `Shipbook.enableInnerLog(true)` prints `paused until …` or `backing off until …`.
* Every request carries `x-shipbook-app-id` and `x-shipbook-sdk: flutter/2.0.0`.
* Calling `Shipbook.start` again with the same app ID and key returns the first call's result without logging in again.
* Removed the optional `url` parameter of `Shipbook.start`, which was never read. Use `Shipbook.setConnectionUrl` to point the SDK at another server.

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
