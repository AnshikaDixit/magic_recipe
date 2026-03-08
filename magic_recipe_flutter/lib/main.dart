import 'package:magic_recipe_client/magic_recipe_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import 'screens/greetings_screen.dart';

/// Sets up a global client object that can be used to talk to the server from
/// anywhere in our app. The client is generated from your server code
/// and is set up to connect to a Serverpod running on a local server on
/// the default port. You will need to modify this to connect to staging or
/// production servers.
/// In a larger app, you may want to use the dependency injection of your choice
/// instead of using a global client object. This is just a simple example.
late final Client client;

late String serverUrl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // When you are running the app on a physical device, you need to set the
  // server URL to the IP address of your computer. You can find the IP
  // address by running `ipconfig` on Windows or `ifconfig` on Mac/Linux.
  //
  // You can set the variable when running or building your app like this:
  // E.g. `flutter run --dart-define=SERVER_URL=https://api.example.com/`.
  //
  // Otherwise, the server URL is fetched from the assets/config.json file or
  // defaults to http://$localhost:8080/ if not found.
  final serverUrl = await getServerUrl();

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authSessionManager = FlutterAuthSessionManager();

  client.auth.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serverpod Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'Serverpod Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  /// Holds the recipe history.
  List<Recipe> _recipeHistory = [];

  /// Holds the last result or null if no result exists yet.
  Recipe? _recipe;

  /// Holds the last error message that we've received from the server or null if no
  /// error exists yet.
  String? _errorMessage;
  final _textEditingController = TextEditingController();
  bool _loading = false;

  void _callGenerateRecipe() async {
    try {
      setState(() {
        _errorMessage = null;
        _recipe = null;
        _loading = true;
      });
      final result = await client.recipes.generateRecipe(
        _textEditingController.text,
      );
      setState(() {
        _errorMessage = null;
        _recipe = result;
        _recipeHistory.insert(0, result);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
        _recipe = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadRecipeHistory() async {
    try {
      final recipes = await client.recipes.getRecipes();
      setState(() => _recipeHistory = recipes);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load recipes: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecipeHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: [
        // Left panel: Recipe history
         Expanded(
           child: DecoratedBox(
             decoration: BoxDecoration(color: Colors.grey[300]),
             child: ListView.builder(
               itemCount: _recipeHistory.length,
               itemBuilder: (context, index) {
                 final recipe = _recipeHistory[index];
                 final firstLineEnd = recipe.text.indexOf('\n');
                 final title = firstLineEnd != -1
                     ? recipe.text.substring(0, firstLineEnd)
                     : recipe.text;
                 return ListTile(
                   title: Text(title),
                   subtitle: Text('${recipe.author} - ${recipe.date}'),
                   onTap: () {
                     setState(() {
                       _recipe = recipe;
                       _textEditingController.text = recipe.ingredients;
                     });
                   },
                 );
               },
             ),
           ),
         ),
         // Right panel: Recipe generator (3x wider)
         Expanded(
           flex: 3,
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 TextField(
                controller: _textEditingController,
                decoration: const InputDecoration(
                  hintText: 'Enter your ingredients for the recipe',
                ),),
                  ElevatedButton(
                onPressed: _loading ? null : _callGenerateRecipe,
                child: _loading
                    ? const Text('Loading...')
                    : const Text('Generate Recipe'),
              ),
                Expanded(
                   child: SingleChildScrollView(
                     child: ResultDisplay(
                  resultMessage: _recipe != null
                      ? '${_recipe?.author} on ${_recipe?.date}:\n${_recipe?.text}'
                    : null,
                  errorMessage: _errorMessage,
                ),
                   ),
                 ),
               ],
             ),
           ),
         ),
        ],
      ),
    );
  }
}
