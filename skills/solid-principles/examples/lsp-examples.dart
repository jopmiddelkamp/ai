// The language (Dart) is only illustrative; the principles apply to any stack.
// LSP — Liskov Substitution Principle
// Subtypes must be substitutable for their base types.
// `Either`/`Failure` stand for whatever result type the codebase uses.

// --- Example 1: Repository with inconsistent error handling ---

// BAD — Implementations signal the same "not found" case in different ways
abstract class WalletRepository {
  Future<Either<Failure, Wallet>> getWallet(String id);
}

class RemoteWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, Wallet>> getWallet(String id) async {
    try {
      final response = await _api.getWallet(id);
      return Right(response.toDomain());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

class LocalWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, Wallet>> getWallet(String id) async {
    final data = await _db.query('wallets', where: 'id = ?', whereArgs: [id]);
    if (data.isEmpty) {
      // LSP violation — throws instead of returning Left
      throw WalletNotFoundException(id);
    }
    return Right(WalletModel.fromMap(data.first).toDomain());
  }
}

// GOOD — Both return Either consistently
class RemoteWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, Wallet>> getWallet(String id) async {
    try {
      final response = await _api.getWallet(id);
      return Right(response.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}

class LocalWalletRepository implements WalletRepository {
  @override
  Future<Either<Failure, Wallet>> getWallet(String id) async {
    final data = await _db.query('wallets', where: 'id = ?', whereArgs: [id]);
    if (data.isEmpty) {
      return Left(NotFoundFailure(entity: 'Wallet', id: id));
    }
    return Right(WalletModel.fromMap(data.first).toDomain());
  }
}

// --- Example 2: Unimplemented methods in a class hierarchy ---

// BAD — Some subtypes can't fulfill the contract
sealed class PaymentMethod {
  Future<PaymentResult> process(double amount);
  Future<void> refund(String transactionId);  // Not all methods support refund
}

class CreditCardPayment extends PaymentMethod {
  @override
  Future<PaymentResult> process(double amount) async {
    return await _cardGateway.charge(amount);
  }

  @override
  Future<void> refund(String transactionId) async {
    await _cardGateway.refund(transactionId);
  }
}

class CryptoPayment extends PaymentMethod {
  @override
  Future<PaymentResult> process(double amount) async {
    return await _cryptoClient.sendPayment(amount);
  }

  @override
  Future<void> refund(String transactionId) {
    // LSP violation — crypto payments can't be refunded
    throw UnsupportedError('Crypto payments cannot be refunded');
  }
}

// GOOD — Separate refundable from non-refundable
sealed class PaymentMethod {
  Future<PaymentResult> process(double amount);
}

// Only refundable methods implement this
abstract class RefundablePaymentMethod extends PaymentMethod {
  Future<void> refund(String transactionId);
}

class CreditCardPayment extends RefundablePaymentMethod {
  @override
  Future<PaymentResult> process(double amount) async {
    return await _cardGateway.charge(amount);
  }

  @override
  Future<void> refund(String transactionId) async {
    await _cardGateway.refund(transactionId);
  }
}

class CryptoPayment extends PaymentMethod {
  @override
  Future<PaymentResult> process(double amount) async {
    return await _cryptoClient.sendPayment(amount);
  }
  // No refund method — not part of the contract for this type
}

// --- Example 3: Type checking in the presentation layer ---

// BAD — Presentation code checks the concrete type to decide what to show
class TransactionRow {
  TransactionRow(this.transaction);

  final Transaction transaction;

  RowViewModel render() {
    // LSP violation — the caller knows about concrete types
    if (transaction is DepositTransaction) {
      return RowViewModel(
        icon: 'arrow_down',
        title: '+${transaction.amount}',
        subtitle: (transaction as DepositTransaction).source,
      );
    } else if (transaction is WithdrawalTransaction) {
      return RowViewModel(
        icon: 'arrow_up',
        title: '-${transaction.amount}',
        subtitle: (transaction as WithdrawalTransaction).destination,
      );
    }
    return RowViewModel.empty();
  }
}

// GOOD — Every subtype fulfills the same contract (polymorphism)
// The contract holds domain facts, not UI details; presentation maps them.
enum Direction { incoming, outgoing }

sealed class Transaction {
  double get amount;
  Direction get direction;
  String get counterparty;
}

class DepositTransaction extends Transaction {
  final String source;

  @override Direction get direction => Direction.incoming;
  @override String get counterparty => source;
}

class WithdrawalTransaction extends Transaction {
  final String destination;

  @override Direction get direction => Direction.outgoing;
  @override String get counterparty => destination;
}

class TransactionRow {
  TransactionRow(this.transaction);

  final Transaction transaction;

  RowViewModel render() {
    final incoming = transaction.direction == Direction.incoming;
    return RowViewModel(
      icon: incoming ? 'arrow_down' : 'arrow_up',
      title: '${incoming ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
      subtitle: transaction.counterparty,
    );
  }
}
