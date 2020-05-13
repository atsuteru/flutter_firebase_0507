import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
  'profile',
  'https://www.googleapis.com/auth/photoslibrary',
  'https://www.googleapis.com/auth/photoslibrary.sharing'
]);

void main() {
  Crashlytics.instance.enableInDevMode = true;
  FlutterError.onError = Crashlytics.instance.recordFlutterError;
  runZoned<Future<void>>(() async {
    runApp(MyApp());
  }, onError: Crashlytics.instance.recordError);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  FirebaseUser _currentUser;

  @override
  void initState() {
    super.initState();
    new Future(() async{
      if (await _handleSignIn(await _googleSignIn.signInSilently())) {
        _handleGetContact();
      }
    });
  }

  Future<void> _handleGetContact() async {
  }

  Future<bool> _handleSignIn(GoogleSignInAccount googleSignInAccount) async {
    if (googleSignInAccount == null) {
      return false;
    }
    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;
    if (user.isAnonymous) {
      return false;
    }
    if (await user.getIdToken() == null) {
      return false;
    }
    final FirebaseUser currentUser = await _auth.currentUser();
    if (user.uid != currentUser.uid) {
      return false;
    }
    setState(() {
      _currentUser = currentUser;
    });
    return true;
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _currentUser = null;
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  Widget _buildGoogleSignInBody() {
    if (_currentUser != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Card(
            color: Colors.lightBlueAccent,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                  _currentUser.photoUrl,
                ),
                radius: 30,
                backgroundColor: Colors.transparent,
              ),
              title: Text(_currentUser.displayName ?? ''),
              subtitle: Text(_currentUser.email ?? ''),
            ),
          ),
          const Text("Signed in successfully."),
          RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: () async{
              if (await _handleSignIn(await _googleSignIn.signIn())) {
                _handleGetContact();
              }
            }
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
            Text(
              'Firebase Crashlytics Tests:',
            ),
            FlatButton(
                child: const Text('Key'),
                onPressed: () {
                  Crashlytics.instance.setString('foo', 'bar');
                }),
            FlatButton(
                child: const Text('Log'),
                onPressed: () {
                  Crashlytics.instance.log('baz');
                }),
            FlatButton(
                child: const Text('Crash'),
                onPressed: () {
                  // Use Crashlytics to throw an error. Use this for
                  // confirmation that errors are being correctly reported.
                  Crashlytics.instance.crash();
                }),
            FlatButton(
                child: const Text('Throw Error'),
                onPressed: () {
                  // Example of thrown error, it will be caught and sent to
                  // Crashlytics.
                  throw StateError('Uncaught error thrown by app.');
                }),
            FlatButton(
                child: const Text('Async out of bounds'),
                onPressed: () {
                  // Example of an exception that does not get caught
                  // by `FlutterError.onError` but is caught by the `onError` handler of
                  // `runZoned`.
                  Future<void>.delayed(const Duration(seconds: 2), () {
                    final List<int> list = <int>[];
                    print(list[100]);
                  });
                }),
            FlatButton(
                child: const Text('Record Error'),
                onPressed: () {
                  try {
                    throw 'error_example';
                  } catch (e, s) {
                    // "context" will append the word "thrown" in the
                    // Crashlytics console.
                    Crashlytics.instance
                        .recordError(e, s, context: 'as an example');
                  }
                }),
            _buildGoogleSignInBody(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
