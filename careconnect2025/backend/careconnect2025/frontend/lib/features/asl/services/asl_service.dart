abstract class AslService { Future<String> textToAsl(String text); }
class MockAslService implements AslService {
  @override Future<String> textToAsl(String text) async => "assets/images/banner.png";
}
