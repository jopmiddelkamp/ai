// The language (Dart) is only illustrative; the principles apply to any stack.
// ISP — Interface Segregation Principle
// No client should be forced to depend on methods it does not use.
// `Either`/`Failure`/`Unit` stand for whatever result type the codebase uses.

// --- Example 1: Fat repository interface ---

// BAD — All consumers depend on full CRUD even if they only read
abstract class TransactionRepository {
  Future<Either<Failure, Transaction>> getById(String id);
  Future<Either<Failure, List<Transaction>>> getByWalletId(String walletId);
  Future<Either<Failure, List<Transaction>>> search(TransactionFilter filter);
  Future<Either<Failure, Unit>> create(Transaction transaction);
  Future<Either<Failure, Unit>> update(Transaction transaction);
  Future<Either<Failure, Unit>> delete(String id);
  Future<Either<Failure, Unit>> bulkCreate(List<Transaction> transactions);
  Future<Either<Failure, TransactionStats>> getStats(String walletId);
}

// The transaction list only needs to read — but depends on all 8 methods
class TransactionListController {
  TransactionListController(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, List<Transaction>>> load(String walletId) =>
      _repository.getByWalletId(walletId);
}

// GOOD — Segregated interfaces
abstract class TransactionReader {
  Future<Either<Failure, Transaction>> getById(String id);
  Future<Either<Failure, List<Transaction>>> getByWalletId(String walletId);
  Future<Either<Failure, List<Transaction>>> search(TransactionFilter filter);
  Future<Either<Failure, TransactionStats>> getStats(String walletId);
}

abstract class TransactionWriter {
  Future<Either<Failure, Unit>> create(Transaction transaction);
  Future<Either<Failure, Unit>> update(Transaction transaction);
  Future<Either<Failure, Unit>> delete(String id);
  Future<Either<Failure, Unit>> bulkCreate(List<Transaction> transactions);
}

// The implementation can implement both
class TransactionRepositoryImpl implements TransactionReader, TransactionWriter {
  // ... all methods
}

// The controller depends only on what it needs
class TransactionListController {
  TransactionListController(this._reader); // Only read methods

  final TransactionReader _reader;

  Future<Either<Failure, List<Transaction>>> load(String walletId) =>
      _reader.getByWalletId(walletId);
}

// --- Example 2: Wallet feature interface ---

// BAD — Interface forces all wallet types to support all features
abstract class WalletService {
  Future<Either<Failure, Wallet>> getWallet(String id);
  Future<Either<Failure, Unit>> deposit(String walletId, double amount);
  Future<Either<Failure, Unit>> withdraw(String walletId, double amount);
  Future<Either<Failure, Unit>> transfer(String from, String to, double amount);
  Future<Either<Failure, Unit>> stake(String walletId, double amount);
  Future<Either<Failure, Unit>> unstake(String walletId, double amount);
  Future<Either<Failure, StakingRewards>> getStakingRewards(String walletId);
}

// Fiat wallet forced to implement staking methods it doesn't support
class FiatWalletService implements WalletService {
  @override
  Future<Either<Failure, Unit>> stake(String walletId, double amount) {
    throw UnimplementedError('Fiat wallets do not support staking');  // ISP violation
  }
  // ...
}

// GOOD — Segregated by capability
abstract class WalletOperations {
  Future<Either<Failure, Wallet>> getWallet(String id);
  Future<Either<Failure, Unit>> deposit(String walletId, double amount);
  Future<Either<Failure, Unit>> withdraw(String walletId, double amount);
  Future<Either<Failure, Unit>> transfer(String from, String to, double amount);
}

abstract class StakingOperations {
  Future<Either<Failure, Unit>> stake(String walletId, double amount);
  Future<Either<Failure, Unit>> unstake(String walletId, double amount);
  Future<Either<Failure, StakingRewards>> getStakingRewards(String walletId);
}

class FiatWalletService implements WalletOperations {
  // Only implements what fiat wallets can do
}

class CryptoWalletService implements WalletOperations, StakingOperations {
  // Implements both — crypto wallets support staking
}

// --- Example 3: Auth interface with mixed concerns ---

// BAD — Auth interface mixes authentication with user management
abstract class AuthService {
  Future<Either<Failure, AuthToken>> login(String email, String password);
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, AuthToken>> refreshToken(String refreshToken);
  Future<Either<Failure, User>> register(RegisterRequest request);
  Future<Either<Failure, Unit>> resetPassword(String email);
  Future<Either<Failure, Unit>> updateProfile(UpdateProfileRequest request);
  Future<Either<Failure, User>> getCurrentUser();
}

// The login screen only needs login — but depends on 7 methods
class LoginController {
  LoginController(this._auth); // Uses 1 of 7 methods from AuthService

  final AuthService _auth;
}

// GOOD — Segregated by concern
abstract class AuthenticationService {
  Future<Either<Failure, AuthToken>> login(String email, String password);
  Future<Either<Failure, Unit>> logout();
  Future<Either<Failure, AuthToken>> refreshToken(String refreshToken);
}

abstract class RegistrationService {
  Future<Either<Failure, User>> register(RegisterRequest request);
}

abstract class UserProfileService {
  Future<Either<Failure, Unit>> resetPassword(String email);
  Future<Either<Failure, Unit>> updateProfile(UpdateProfileRequest request);
  Future<Either<Failure, User>> getCurrentUser();
}

class LoginController {
  LoginController(this._auth); // Only authentication — no registration or profile

  final AuthenticationService _auth;
}
