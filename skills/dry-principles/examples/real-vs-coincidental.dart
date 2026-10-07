// DRY — Real vs Coincidental Similarity
// The language is illustrative only; the reasoning applies to any stack.
// `Controller` stands for whatever state holder or service class the codebase uses.
// "Do these change for the same reason?"

// --- Scenario 1: Real Duplication (Extract) ---

// BAD — Same fee calculation in two controllers
// When the fee structure changes, BOTH must update.
class PaymentController {
  Future<void> initiatePayment(double amount) async {
    var fee = amount * 0.015; // Fee calculation — copy 1
    if (amount > 10000) {
      fee = amount * 0.01;   // Volume discount — copy 1
    }

    final payment = Payment(amount: amount, fee: fee);
    // ...
  }
}

class TransferController {
  Future<void> initiateTransfer(double amount) async {
    var fee = amount * 0.015; // Fee calculation — copy 2
    if (amount > 10000) {
      fee = amount * 0.01;   // Volume discount — copy 2
    }

    final transfer = Transfer(amount: amount, fee: fee);
    // ...
  }
}

// GOOD — Extracted to a single source of truth
class FeeCalculator {
  double calculate(double amount) {
    final rate = amount > 10000 ? 0.01 : 0.015;
    return amount * rate;
  }
}

class PaymentController {
  final FeeCalculator _feeCalculator;

  PaymentController(this._feeCalculator);

  Future<void> initiatePayment(double amount) async {
    final fee = _feeCalculator.calculate(amount);
    final payment = Payment(amount: amount, fee: fee);
    // ...
  }
}

class TransferController {
  final FeeCalculator _feeCalculator;

  TransferController(this._feeCalculator);

  Future<void> initiateTransfer(double amount) async {
    final fee = _feeCalculator.calculate(amount);
    final transfer = Transfer(amount: amount, fee: fee);
    // ...
  }
}

// --- Scenario 2: Coincidental Similarity (Keep Separate) ---

// GOOD — These look similar but represent different business concepts
class PaymentFormState {
  final double amount;
  final String currency;
  final String description;
  final String walletId;

  const PaymentFormState({
    required this.amount,
    required this.currency,
    required this.description,
    required this.walletId,
  });
}

class TransferFormState {
  final double amount;
  final String currency;
  final String description;
  final String sourceWalletId;      // Already different
  final String destinationWalletId; // Transfer-specific

  const TransferFormState({
    required this.amount,
    required this.currency,
    required this.description,
    required this.sourceWalletId,
    required this.destinationWalletId,
  });
}

// BAD — Premature extraction: "They both have amount, currency, description!"
// "SharedHelper" smell — too generic a name
class TransactionFormState {
  final double amount;
  final String currency;
  final String description;

  const TransactionFormState({
    required this.amount,
    required this.currency,
    required this.description,
  });
}
// When PaymentFormState adds recurringSchedule and TransferFormState adds
// destinationWalletId, this shared state becomes a wrong abstraction.
// DRY: Coincidental similarity — payments and transfers evolve independently

// --- Scenario 3: Wrong Abstraction (Inline Back) ---

// BAD — Base controller accumulating behavior to serve different screens
abstract class BaseTransactionController {
  final bool isTransfer;        // Boolean flag
  final bool requiresApproval;  // Boolean flag

  BaseTransactionController({
    required this.isTransfer,
    required this.requiresApproval,
  });

  Future<void> processTransaction(double amount) async {
    if (isTransfer) {
      await _validateTransferRules(amount);
    } else {
      await _validatePaymentRules(amount);
    }

    final fee = isTransfer
        ? _calculateTransferFee(amount)
        : _calculatePaymentFee(amount);

    if (requiresApproval) {
      await _submitForApproval(amount, fee);
    } else {
      await _executeImmediately(amount, fee);
    }
  }

  // Subclasses must implement — but they only use half the methods
  Future<void> _validateTransferRules(double amount);
  Future<void> _validatePaymentRules(double amount);
  // ...
}

// GOOD — Inlined back to separate, clear controllers
class PaymentController {
  final FeeCalculator _feeCalculator;
  final PaymentRepository _paymentRepository;

  PaymentController(this._feeCalculator, this._paymentRepository);

  Future<void> processPayment(double amount) async {
    _validatePaymentRules(amount);
    final fee = _feeCalculator.calculate(amount);
    await _executePayment(amount, fee);
  }

  // ...
}

class TransferController {
  final FeeCalculator _feeCalculator;
  final TransferRepository _transferRepository;

  TransferController(this._feeCalculator, this._transferRepository);

  Future<void> processTransfer(double amount) async {
    _validateTransferRules(amount);
    final fee = _feeCalculator.calculate(amount);

    if (_requiresApproval(amount)) {
      await _submitForApproval(amount, fee);
    } else {
      await _executeTransfer(amount, fee);
    }
  }

  // ...
}

// FeeCalculator is still shared — that's REAL knowledge duplication.
// The base controller was coincidental similarity that diverged.
// DRY: Inlined wrong abstraction — fee calculation remains shared (real knowledge),
// processing workflows separated (coincidental similarity)
