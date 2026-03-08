import 'package:magic_recipe_server/src/generated/protocol.dart';
import 'package:magic_recipe_server/src/recipes/services/recipe_ai_services.dart';
import 'package:serverpod/serverpod.dart';

class RecipesEndpoint extends Endpoint {
  Future<Recipe> generateRecipe(Session session, String ingredients) async {
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey') ?? 'mock_api_key';
    final service = RecipeAIService.fromApiKey(geminiApiKey);
    return service.generateRecipe(session, ingredients);
  }

  /// Returns a list of all recipes.
  Future<List<Recipe>> getRecipes(Session session) async {
    return Recipe.db.find(
      session,
      where: (t) => t.deletedAt.equals(null),
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }

  Future<void> deleteRecipe(Session session, int recipeId) async {
    final recipe = await Recipe.db.findById(session, recipeId);
    if (recipe == null) {
      throw Exception('Recipe not found');
    }

    final deletedRecipe = recipe.copyWith(deletedAt: DateTime.now());
    await Recipe.db.updateRow(session, deletedRecipe);
  }
}
