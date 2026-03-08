import 'package:magic_recipe_server/src/generated/protocol.dart';
import 'package:magic_recipe_server/src/recipes/services/recipe_ai_services.dart';
import 'package:serverpod/serverpod.dart';

class RecipesEndpoint extends Endpoint {
  Future<Recipe> generateRecipe(Session session, String ingredients) async {
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey')!;
    final service = RecipeAIService.fromApiKey(geminiApiKey);
    return service.generateRecipe(session, ingredients);
  }

  /// Returns a list of all recipes.
  Future<List<Recipe>> getRecipes(Session session) async {
    return Recipe.db.find(
      session,
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }
}
    