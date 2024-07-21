import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RecipeListScreen(),
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _recipeController = TextEditingController();
  final CollectionReference _recipes = FirebaseFirestore.instance.collection('recipes');

  void _addRecipe() async {
    final String recipeText = _recipeController.text;
    if (recipeText.isNotEmpty) {
      await _recipes.add({'text': recipeText, 'category': 'Uncategorized'});
      _recipeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe App'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: RecipeSearchDelegate(_searchController.text),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _recipeController,
                    decoration: InputDecoration(
                      labelText: 'Enter a recipe',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addRecipe,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _recipes.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final recipes = snapshot.data!.docs;
                return ListView(
                  children: recipes.map((doc) {
                    final text = doc['text'];
                    final category = doc['category'];
                    return ListTile(
                      title: Text(text),
                      subtitle: Text('Category: $category'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _recipes.doc(doc.id).delete(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeSearchDelegate extends SearchDelegate {
  final String queryText;

  RecipeSearchDelegate(this.queryText);

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestions = [
      // Here you can define a list of suggestions based on your queryText
    ];

    return ListView(
      children: suggestions.map((suggestion) {
        return ListTile(
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      }).toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('recipes')
          .where('text', isGreaterThanOrEqualTo: queryText)
          .where('text', isLessThanOrEqualTo: queryText + '\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final recipes = snapshot.data!.docs;
        return ListView(
          children: recipes.map((doc) {
            final text = doc['text'];
            return ListTile(
              title: Text(text),
            );
          }).toList(),
        );
      },
    );
  }
}
