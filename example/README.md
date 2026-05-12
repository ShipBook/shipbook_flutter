# Shipbook package for Flutter

## About Shipbook
[Shipbook](https://www.shipbook.io) gives you the power to remotely gather, search and analyze your user logs and exceptions in the cloud, on a per-user & session basis.

---

## Running the   example

Credentials are injected at compile time via `--dart-define`. Put them in `example/.env` (gitignored):

```
SHIPBOOK_APP_ID=<your-app-id>
SHIPBOOK_APP_KEY=<your-app-key>
```

Then run:

```bash
flutter run --dart-define-from-file=.env
```

The IntelliJ run config is already set up with this flag, so ▶️ in the IDE just works.

## Resources
* [Shipbook Documentation](https://docs.shipbook.io)

## Author

Elisha Sterngold ([ShipBook Ltd.](https://www.shipbook.io))

## License

ShipBookSDK is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
