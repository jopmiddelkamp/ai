// The language (Dart) is only illustrative; the principles apply to any stack.
// OCP — Open/Closed Principle
// Open for extension, closed for modification.
// `Either`/`Failure` stand for whatever result type the codebase uses.

// --- Example 1: Payment status handling with an if-else chain ---

// BAD — Adding a new status requires modifying this presenter
class PaymentStatusBadge {
  PaymentStatusBadge(this.status);

  final PaymentStatus status;

  BadgeViewModel render() {
    // Growing if-else chain — new status = modify this class
    if (status == PaymentStatus.pending) {
      return const BadgeViewModel('Pending', 'orange', 'schedule');
    } else if (status == PaymentStatus.completed) {
      return const BadgeViewModel('Completed', 'green', 'check');
    } else if (status == PaymentStatus.failed) {
      return const BadgeViewModel('Failed', 'red', 'error');
    } else if (status == PaymentStatus.refunded) {
      return const BadgeViewModel('Refunded', 'blue', 'undo');
    } else {
      return const BadgeViewModel('Unknown', 'grey', 'help');
    }
  }
}

// GOOD — Each status defines its own presentation data
sealed class PaymentStatus {
  String get label;
  String get color;
  String get icon;

  const PaymentStatus();
}

class PendingStatus extends PaymentStatus {
  @override String get label => 'Pending';
  @override String get color => 'orange';
  @override String get icon => 'schedule';
}

class CompletedStatus extends PaymentStatus {
  @override String get label => 'Completed';
  @override String get color => 'green';
  @override String get icon => 'check';
}

// New status? Add a new class. PaymentStatusBadge stays unchanged.
class PaymentStatusBadge {
  PaymentStatusBadge(this.status);

  final PaymentStatus status;

  BadgeViewModel render() => BadgeViewModel(status.label, status.color, status.icon);
}
// Note: if the codebase keeps UI details out of domain types, put this mapping
// in a presentation-side lookup per status instead. If it already uses an
// exhaustive switch over a sealed type, that is also acceptable; the compiler
// flags every missed case.

// --- Example 2: Validation rule expansion ---

// BAD — Adding a validation rule requires modifying the validator
class TransferValidator {
  Either<Failure, void> validate(TransferRequest request) {
    if (request.amount <= 0) {
      return const Left(ValidationFailure('Amount must be positive'));
    }
    if (request.amount > 10000) {
      return const Left(ValidationFailure('Amount exceeds limit'));
    }
    if (request.sourceWalletId == request.destinationWalletId) {
      return const Left(ValidationFailure('Cannot transfer to same wallet'));
    }
    // New rule? Modify this method.
    return const Right(null);
  }
}

// GOOD — Rules are composable and extensible
abstract class ValidationRule<T> {
  Either<Failure, void> validate(T input);
}

class PositiveAmountRule extends ValidationRule<TransferRequest> {
  @override
  Either<Failure, void> validate(TransferRequest request) {
    if (request.amount <= 0) {
      return const Left(ValidationFailure('Amount must be positive'));
    }
    return const Right(null);
  }
}

class AmountLimitRule extends ValidationRule<TransferRequest> {
  @override
  Either<Failure, void> validate(TransferRequest request) {
    if (request.amount > 10000) {
      return const Left(ValidationFailure('Amount exceeds limit'));
    }
    return const Right(null);
  }
}

class DifferentWalletsRule extends ValidationRule<TransferRequest> {
  @override
  Either<Failure, void> validate(TransferRequest request) {
    if (request.sourceWalletId == request.destinationWalletId) {
      return const Left(ValidationFailure('Cannot transfer to same wallet'));
    }
    return const Right(null);
  }
}

// Composite validator — new rule = add a new class, register it in the list
class CompositeValidator<T> {
  final List<ValidationRule<T>> _rules;

  const CompositeValidator(this._rules);

  Either<Failure, void> validate(T input) {
    for (final rule in _rules) {
      final result = rule.validate(input);
      if (result.isLeft()) return result;
    }
    return const Right(null);
  }
}
// Note: three fixed rules in one method can be the simpler choice. Apply this
// pattern when rules change often or vary per context (see kiss-principles).

// --- Example 3: Data source strategy ---

// BAD — Adding a data source requires modifying the repository
class WalletRepository {
  final WalletApi _api;
  final WalletLocalDb _localDb;

  Future<Either<Failure, Wallet>> getWallet(String id) async {
    try {
      final model = await _api.getWallet(id);
      return Right(model.toDomain());
    } catch (e) {
      // Fallback to local — but adding a third source means modifying this
      final cached = await _localDb.getWallet(id);
      if (cached != null) return Right(cached.toDomain());
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

// GOOD — Data sources are pluggable via the strategy pattern
abstract class WalletDataSource {
  Future<WalletModel?> getWallet(String id);
  int get priority;
}

class RemoteWalletDataSource extends WalletDataSource {
  final WalletApi _api;

  @override int get priority => 1;

  @override
  Future<WalletModel?> getWallet(String id) async {
    try {
      return await _api.getWallet(id);
    } catch (_) {
      return null;
    }
  }
}

class LocalWalletDataSource extends WalletDataSource {
  final WalletLocalDb _localDb;

  @override int get priority => 2;

  @override
  Future<WalletModel?> getWallet(String id) => _localDb.getWallet(id);
}

// The repository tries sources in priority order — a new source = a new class
class WalletRepository {
  WalletRepository(List<WalletDataSource> sources)
      : _sources = [...sources]..sort((a, b) => a.priority.compareTo(b.priority));

  final List<WalletDataSource> _sources;

  Future<Either<Failure, Wallet>> getWallet(String id) async {
    for (final source in _sources) {
      final model = await source.getWallet(id);
      if (model != null) return Right(model.toDomain());
    }
    return Left(NotFoundFailure(entity: 'Wallet', id: id));
  }
}
