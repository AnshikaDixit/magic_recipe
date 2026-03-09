import 'package:magic_recipe_server/src/generated/protocol.dart';
import 'package:magic_recipe_server/src/recipes/exceptions/recipe_exception.dart';
import 'package:magic_recipe_server/src/recipes/services/recipe_ai_services.dart';
import 'package:serverpod/serverpod.dart';

class RecipesEndpoint extends Endpoint {
 String _getUserId(Session session) {
  final userId = session.authenticated?.userIdentifier;
  if (userId == null) {
    throw RecipeException('User not authenticated');
  }
  return userId;
 }

  @override
  bool get requireLogin => true;

  Future<Recipe> generateRecipe(Session session, String ingredients) async {
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey') ?? 'mock_api_key';
    final service = RecipeAIService.fromApiKey(geminiApiKey);
    final userId = _getUserId(session);
    return service.generateRecipe(session, userId, ingredients);
  }

  /// Returns a list of all recipes.
  Future<List<Recipe>> getRecipes(Session session) async {
    final userId = _getUserId(session);
    return Recipe.db.find(
      session,
      where: (t) => t.deletedAt.equals(null) & t.userId.equals(userId),
      orderBy: (t) => t.date,
      orderDescending: true,
    );
  }

  Future<void> deleteRecipe(Session session, int recipeId) async {
  final userId = _getUserId(session);
  final recipe = await Recipe.db.findById(session, recipeId);

  if (recipe == null) {
    throw RecipeException('Recipe not found');
  }

  if (recipe.userId != userId) {
    throw RecipeException(
      'Unauthorized: You can only delete your own recipes',
    );
  }

  await Recipe.db.updateRow(
    session,
    recipe.copyWith(deletedAt: DateTime.now()),
  );
}
}
