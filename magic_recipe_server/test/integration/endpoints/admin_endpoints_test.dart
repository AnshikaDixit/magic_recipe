import 'package:test/test.dart';
import '../test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('admin_endpoints_test', (
    unAuthSessionBuilder,
    endpoints,
  ) async {
    test("No endpoint is callable without authentication", () {
       expect(
        () => endpoints.admin.listUsers(unAuthSessionBuilder),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );

      expect(
        () => endpoints.admin.blockUser(unAuthSessionBuilder, 1),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );

      expect(
        () => endpoints.admin.unblockUser(unAuthSessionBuilder, 1),
        throwsA(isA<ServerpodUnauthenticatedException>()),
      );
    });


    test("no endpoint is callable without admin scope", (){
      final sessionBuilder = unAuthSessionBuilder.copyWith(
         authentication: AuthenticationOverride.authenticationInfo("1", {}));
      expect(
        () => endpoints.admin.listUsers(sessionBuilder),
        throwsA(isA<ServerpodInsufficientAccessException>()),
      );
      expect(
        () => endpoints.admin.blockUser(sessionBuilder, 1),
        throwsA(isA<ServerpodInsufficientAccessException>()),
      );
      expect(
        () => endpoints.admin.unblockUser(sessionBuilder, 1),
        throwsA(isA<ServerpodInsufficientAccessException>()),
      );
    });
  });
}
