// KISS — Over-Engineering Anti-Patterns — Examples
// The language (Dart/Flutter) is only illustrative; the patterns apply to any stack.
// The domain (payments) is an example. The `// KISS:` comments show the marker
// convention; use it only if the codebase already does.
// Simplest solution that meets current requirements wins.

// --- Example 1: Premature Polymorphism ---

// BAD — Abstract class with single implementation, same module, no test isolation need
// Both live in the same layer or module — no boundary to cross.
// Pure calculation with no side effects — nothing to mock.
abstract class PaymentCalculator {
  double calculateTotal(Payment payment);
}

class DefaultPaymentCalculator implements PaymentCalculator {
  @override
  double calculateTotal(Payment payment) {
    return payment.amount + payment.fee;
  }
}

// Possibly registered in a DI container too. Only one implementation exists.
// The abstract class adds a file, maybe a registration, and indirection — for zero benefit.

// GOOD — Concrete class, no unnecessary abstraction
class PaymentCalculator {
  double calculateTotal(Payment payment) {
    return payment.amount + payment.fee;
  }
}

// KISS: Single implementation, same module, pure logic — concrete class sufficient
// If a second implementation, test mock, or cross-team contract becomes needed, add the abstraction then.

// NOTE: If the codebase uses layered architecture and PaymentCalculator lived in
// infrastructure but was consumed from the application layer, the abstract class
// WOULD be justified (Dependency Rule).
// Similarly, if this class had side effects (API calls, DB) that tests need to mock,
// the abstraction WOULD be justified for test isolation.

// --- Example 2: Excessive Widget Abstraction ---

// BAD — Generic card widget used at one concrete type
class GenericCardWidget<T> extends StatelessWidget {
  final T data;
  final String Function(T) titleBuilder;
  final String Function(T) subtitleBuilder;
  final IconData Function(T) iconBuilder;
  final VoidCallback? onTap;

  const GenericCardWidget({
    super.key,
    required this.data,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.iconBuilder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(iconBuilder(data)),
        title: Text(titleBuilder(data)),
        subtitle: Text(subtitleBuilder(data)),
        onTap: onTap,
      ),
    );
  }
}

// Used in exactly ONE place:
// GenericCardWidget<Payment>(
//   data: payment,
//   titleBuilder: (p) => p.description,
//   subtitleBuilder: (p) => p.formattedAmount,
//   iconBuilder: (p) => Icons.payment,
// )

// GOOD — Purpose-built widget for the one actual use case
class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;

  const PaymentCard({super.key, required this.payment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.payment),
        title: Text(payment.description),
        subtitle: Text(payment.formattedAmount),
        onTap: onTap,
      ),
    );
  }
}

// KISS: Concrete widget; extract only when another card shares the same rule

// --- Example 3: Pattern Worship in State Management ---
// Shown with Riverpod + freezed; the same applies to any state-management library.

// BAD — Full notifier class with generated immutable state for a boolean toggle
@freezed
class PasswordVisibilityState with _$PasswordVisibilityState {
  const factory PasswordVisibilityState({
    @Default(false) bool isVisible,
  }) = _PasswordVisibilityState;
}

@riverpod
class PasswordVisibilityNotifier extends _$PasswordVisibilityNotifier {
  @override
  PasswordVisibilityState build() => const PasswordVisibilityState();

  void toggle() {
    state = state.copyWith(isVisible: !state.isVisible);
  }
}

// Freezed state, generated provider, notifier class — for a boolean flip.

// GOOD — The library's simplest state holder for a boolean toggle
final passwordVisibleProvider = StateProvider<bool>((ref) => false);

// Usage: ref.read(passwordVisibleProvider.notifier).state = !ref.read(passwordVisibleProvider);

// Or even simpler — local widget state if the value doesn't need to leave the widget.
// KISS: Simplest state holder for simple state, full notifier when state is complex

// --- Example 4: KISS > DRY — Independent pages over forced shared base ---

// BAD — Shared base widget forcing identical structure on different pages
abstract class BaseTransactionPage extends StatelessWidget {
  String get title;
  IconData get icon;
  List<Widget> buildFormFields(BuildContext context);
  Future<void> onSubmit(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Icon(icon, size: 48),
          ...buildFormFields(context),
          ElevatedButton(
            onPressed: () => onSubmit(context),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// Deposit and Withdrawal pages both have "title, icon, form, submit" — but:
// - Deposit has a single amount field
// - Withdrawal has amount + destination + compliance checkbox
// The shared base forces the same scaffold shape on both.

// GOOD — Two independent, focused pages
class DepositPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit')),
      body: Column(
        children: [
          const Icon(Icons.add_circle, size: 48),
          AmountField(onChanged: (v) { /* ... */ }),
          ElevatedButton(
            onPressed: () { /* submit deposit */ },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }
}

class WithdrawalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: Column(
        children: [
          const Icon(Icons.remove_circle, size: 48),
          AmountField(onChanged: (v) { /* ... */ }),
          DestinationField(onChanged: (v) { /* ... */ }),
          ComplianceCheckbox(onChanged: (v) { /* ... */ }),
          ElevatedButton(
            onPressed: () { /* submit withdrawal */ },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

// Minor duplication (Scaffold, AppBar, Column) is fine — it's framework boilerplate.
// Each page evolves independently as business requirements diverge.
// KISS: Duplicate preferred — different business reasons will cause divergence
