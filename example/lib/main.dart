import 'package:flutter/material.dart';
import 'package:shipbook_flutter/shipbook_flutter.dart';
final log = Shipbook.getLogger("main");

void main() {
  runApp(const MyApp());
  Shipbook.enableInnerLog(true);
  const connectionUrl = String.fromEnvironment('SHIPBOOK_URL');
  const appId = String.fromEnvironment('SHIPBOOK_APP_ID');
  const appKey = String.fromEnvironment('SHIPBOOK_APP_KEY');
  if (connectionUrl.isNotEmpty) Shipbook.setConnectionUrl(connectionUrl);
  Shipbook.start(appId, appKey);
}

class RegisterButton extends StatefulWidget {
  const RegisterButton({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterButtonState createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<RegisterButton> {
  bool isUserRegistered = false;
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          if (isUserRegistered) {
            Shipbook.logout();
            isUserRegistered = false;
          } else {
            isUserRegistered = true;
            Shipbook.registerUser('test$counter', fullName: 'Test User $counter', email: 'test$counter@test.com', additionalInfo: {'key1': 'value1', 'key2': 'value2'});
            counter++;
          }
        });
      },
      child: Text(!isUserRegistered ? 'Register user [test$counter]' : 'Logout from Shipbook'),
    );
  }
}

class ScreenButton extends StatelessWidget {
  const ScreenButton({super.key, required this.screenName});

  final String screenName;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Shipbook.screen(screenName);
      },
      child: Text('Set screen to $screenName'),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shipbook Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Shipbook Example'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  Widget _logButton(BuildContext context, String label, VoidCallback action) {
    return TextButton(
      onPressed: () {
        action();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sent: $label'), duration: const Duration(seconds: 1)),
        );
      },
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const RegisterButton(),
            const ScreenButton(screenName: 'Home'),
            const Divider(),
            const Text('Log Levels', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                _logButton(context, 'Error', () => log.e('Test error message')),
                _logButton(context, 'Warning', () => log.w('Test warning message')),
                _logButton(context, 'Info', () => log.i('Test info message')),
                _logButton(context, 'Debug', () => log.d('Test debug message')),
                _logButton(context, 'Verbose', () => log.v('Test verbose message')),
              ],
            ),
            const Divider(),
            _logButton(context, 'Log Exception', () {
              try {
                throw StateError('Test exception from example app');
              } catch (e) {
                log.e('Caught exception', e as Error);
              }
            }),
            _logButton(context, 'Throw Uncaught Exception', () {
              throw StateError('Uncaught exception from example app');
            }),
          ],
        ),
      ),
    );
  }
}
