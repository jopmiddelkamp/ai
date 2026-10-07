// The language (Dart) is only illustrative; the principles apply to any stack.
// SRP — Single Responsibility Principle
// Each class should have only one reason to change.
// `Either`/`Failure` stand for whatever result or error type the codebase uses.

// --- Example 1: State holder doing too much ---

// BAD — WalletController handles state, validation, AND navigation
class WalletController {
  WalletController(this._api, this._router);

  final WalletApi _api;
  final Router _router;

  WalletState state = const WalletState.loading();

  Future<void> load(String walletId) async {
    // Validation concern
    if (walletId.isEmpty) {
      throw ArgumentError('Invalid wallet ID');
    }

    final result = await _api.getWallet(walletId);

    // Navigation concern — a state holder shouldn't know about routes
    if (result.requiresVerification) {
      _router.push('/verify');
    }

    state = WalletState.loaded(result);
  }
}

// GOOD — The controller manages state only; other concerns live elsewhere
class WalletController {
  WalletController(this._api);

  final WalletApi _api;

  Wallet? wallet;

  Future<void> load(String walletId) async {
    wallet = await _api.getWallet(walletId);
  }
}
// Navigation is handled by the UI layer reacting to state
// Error messages are rendered by the presentation layer

// --- Example 2: Repository with mixed concerns ---

// BAD — Repository does caching, connectivity checks, and data mapping
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remote;
  final WalletLocalDataSource _local;
  final ConnectivityChecker _connectivity;

  @override
  Future<Either<Failure, Wallet>> getWallet(String id) async {
    // Connectivity concern
    if (!await _connectivity.hasConnection) {
      final cached = await _local.getCachedWallet(id);
      if (cached != null) return Right(cached.toDomain());
      return const Left(NetworkFailure());
    }

    try {
      final model = await _remote.getWallet(id);
      // Caching concern mixed with data access
      await _local.cacheWallet(model);
      // Mapping concern — toDomain() is fine but mixed with the rest
      return Right(model.toDomain());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

// GOOD — Repository focuses on data coordination
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remote;

  @override
  Future<Either<Failure, Wallet>> getWallet(String id) async {
    try {
      final model = await _remote.getWallet(id);
      return Right(model.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
// Caching handled at the data source level or via a caching decorator
// Connectivity handled by the HTTP client or an interceptor

// --- Example 3: Domain entity with formatting ---

// BAD — Entity formats its own display values
class Payment {
  final String id;
  final double amount;
  final String currency;
  final DateTime createdAt;

  // Display concern — domain shouldn't format for UI
  String get formattedAmount => '${currency} ${amount.toStringAsFixed(2)}';

  // Date formatting — UI concern
  String get formattedDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}

// GOOD — Entity contains only domain state and behavior
class Payment {
  final String id;
  final Money amount;
  final PaymentStatus status;
  final DateTime createdAt;

  bool get isPending => status == PaymentStatus.pending;
  bool get canBeRefunded => status == PaymentStatus.completed &&
      DateTime.now().difference(createdAt).inDays <= 30;
}
// Formatting lives in the presentation layer (formatters, view models, or UI components)
