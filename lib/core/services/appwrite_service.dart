import 'package:appwrite/appwrite.dart';

class AppwriteService {
  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;

  // Singleton instance
  static final AppwriteService _instance = AppwriteService._internal();

  factory AppwriteService() {
    return _instance;
  }

  AppwriteService._internal() {
    const endpoint = String.fromEnvironment('APPWRITE_ENDPOINT', defaultValue: 'https://cloud.appwrite.io/v1');
    const projectId = String.fromEnvironment('APPWRITE_PROJECT_ID', defaultValue: '66504a43000b991b151e');
    client = Client()
      ..setEndpoint(endpoint)
      ..setProject(projectId)
      ..setSelfSigned(status: true);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
  }
}
