// The language (Dart) is only illustrative; the principles apply to any stack.
// DIP — Dependency Inversion Principle
// Depend on abstractions, not concretions.
// `Either`/`Failure` stand for whatever result type the codebase uses.
// Dependencies are passed through constructors here; wire them the way the
// codebase already does (DI container, provider system, composition root).

// --- Example 1: Business logic depending on a concrete HTTP client ---

// BAD — Directly constructs a concrete HTTP client
class PaymentListController {
  Future<List<Payment>> load(String walletId) async {
    final http = HttpClient();  // Concrete HTTP client, untestable
    final json = await http.getJsonList('/api/wallets/$walletId/payments');
    return json.map((j) => PaymentModel.fromJson(j).toDomain()).toList();
  }
}

// GOOD — Depends on an abstraction supplied from outside
class PaymentListController {
  PaymentListController(this._repository);

  final PaymentRepository _repository;

  Future<Either<Failure, List<Payment>>> load(String walletId) =>
      _repository.getByWalletId(walletId);
}

// The abstraction lives with the code that uses it
// (in the domain or application layer, if the codebase has layers)
abstract class PaymentRepository {
  Future<Either<Failure, List<Payment>>> getByWalletId(String walletId);
}

// The implementation lives with the infrastructure code
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Payment>>> getByWalletId(String walletId) async {
    try {
      final models = await _remote.getPaymentsByWalletId(walletId);
      return Right(models.map((m) => m.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}

// --- Example 2: Direct access to a concrete key-value store ---

// BAD — Application logic depends directly on a concrete storage library
class UserSettingsService {
  Future<void> saveThemePreference(bool isDarkMode) async {
    // Direct dependency on concrete storage mechanism
    final store = await KeyValueStoreLibrary.getInstance();
    await store.setBool('dark_mode', isDarkMode);
  }

  Future<bool> getThemePreference() async {
    final store = await KeyValueStoreLibrary.getInstance();
    return store.getBool('dark_mode') ?? false;
  }

  Future<void> saveLanguage(String languageCode) async {
    final store = await KeyValueStoreLibrary.getInstance();
    await store.setString('language', languageCode);
  }
}

// GOOD — Depend on an abstraction for local storage
abstract class LocalStorage {
  Future<void> setBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
}

class UserSettingsService {
  final LocalStorage _storage;

  const UserSettingsService(this._storage);

  Future<void> saveThemePreference(bool isDarkMode) async {
    await _storage.setBool('dark_mode', isDarkMode);
  }

  Future<bool> getThemePreference() async {
    return await _storage.getBool('dark_mode') ?? false;
  }
}

// Library-backed implementation in infrastructure code
class LibraryBackedStorage implements LocalStorage {
  final KeyValueStoreLibrary _store;

  const LibraryBackedStorage(this._store);

  @override
  Future<void> setBool(String key, bool value) => _store.setBool(key, value);

  @override
  Future<bool?> getBool(String key) async => _store.getBool(key);

  // ... other methods
}

// --- Example 3: Direct platform API access ---

// BAD — Feature code directly calls a platform-specific plugin
class BiometricAuthService {
  Future<bool> authenticate() async {
    // Direct dependency on a concrete plugin
    final plugin = BiometricPlugin();
    final canAuth = await plugin.canCheckBiometrics;
    if (!canAuth) return false;

    return await plugin.authenticate(
      reason: 'Authenticate to access your wallet',
      biometricOnly: true,
    );
  }
}

// GOOD — Abstract the biometric capability
abstract class BiometricAuthenticator {
  Future<bool> isAvailable();
  Future<Either<Failure, bool>> authenticate({required String reason});
}

class BiometricAuthService {
  final BiometricAuthenticator _authenticator;

  const BiometricAuthService(this._authenticator);

  Future<Either<Failure, bool>> authenticateForWalletAccess() async {
    final available = await _authenticator.isAvailable();
    if (!available) return const Left(BiometricNotAvailableFailure());

    return _authenticator.authenticate(
      reason: 'Authenticate to access your wallet',
    );
  }
}

// Platform implementation in infrastructure code
class PluginBiometricAuthenticator implements BiometricAuthenticator {
  final BiometricPlugin _plugin;

  const PluginBiometricAuthenticator(this._plugin);

  @override
  Future<bool> isAvailable() => _plugin.canCheckBiometrics;

  @override
  Future<Either<Failure, bool>> authenticate({required String reason}) async {
    try {
      final result = await _plugin.authenticate(
        reason: reason,
        biometricOnly: true,
      );
      return Right(result);
    } catch (e) {
      return Left(BiometricFailure(message: e.toString()));
    }
  }
}
