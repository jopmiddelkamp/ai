// DRY — DAMP Testing
// The language and test libraries are illustrative only; the rules apply to any stack.
// `stateTest` stands for whatever state-transition test helper the codebase uses
// (setUp / build / act / expect). Mocks use a mocktail-style API.
// DRY the "how" (infrastructure). Allow duplication in the "what" (scenarios).

// === BAD: Over-DRY Test Setup ===

// All mocks created for every test group — most unused by individual tests
void main() {
  late MockWalletRepository mockWalletRepository;
  late MockPaymentRepository mockPaymentRepository;
  late MockTransferRepository mockTransferRepository;
  late MockNotificationService mockNotificationService;
  late MockAuthRepository mockAuthRepository;
  late MockAnalyticsService mockAnalyticsService;
  late FeeCalculator feeCalculator;

  setUp(() {
    mockWalletRepository = MockWalletRepository();
    mockPaymentRepository = MockPaymentRepository();
    mockTransferRepository = MockTransferRepository();
    mockNotificationService = MockNotificationService();
    mockAuthRepository = MockAuthRepository();
    mockAnalyticsService = MockAnalyticsService();
    feeCalculator = FeeCalculator();

    // 30+ lines of default mock behavior — which ones matter for which test?
    when(() => mockWalletRepository.getWallets(
      page: any(named: 'page'),
      pageSize: any(named: 'pageSize'),
    )).thenAnswer((_) async => []);

    when(() => mockPaymentRepository.create(any()))
        .thenAnswer((_) async => {});

    // ... 20 more mock setups ...
  });

  group('PaymentController', () {
    stateTest<PaymentController, PaymentState>(
      'initiates payment',
      build: () => PaymentController(
        mockPaymentRepository,    // Uses this
        mockWalletRepository,     // Might use this?
        mockTransferRepository,   // Definitely doesn't use this
        mockNotificationService,  // Maybe?
        mockAuthRepository,       // No idea
        mockAnalyticsService,     // Who knows
        feeCalculator,
      ),
      act: (controller) => controller.initiatePayment(500),
      expect: () => [/* ... */],
    );
  });
}

// Problems:
// 1. Can't tell which mocks matter for each test
// 2. Default mock behavior hides test preconditions
// 3. Changing one mock's default breaks unrelated tests
// 4. Must read setUp() to understand ANY test

// === GOOD: DAMP Tests with Explicit Setup ===

// Shared infrastructure: test helpers and builders (DRY these)
Wallet createTestWallet({
  double balance = 1000,
  String currency = 'USDC',
}) {
  return Wallet(
    id: 'wallet-${DateTime.now().millisecondsSinceEpoch}',
    balance: balance,
    currency: currency,
  );
}

Payment createTestPayment({
  required double amount,
  double? fee,
  PaymentStatus status = PaymentStatus.pending,
}) {
  return Payment(
    id: 'payment-${DateTime.now().millisecondsSinceEpoch}',
    amount: amount,
    fee: fee ?? amount * 0.015,
    status: status,
  );
}

// Actual tests: each tells a complete story
void main() {
  group('PaymentController', () {
    group('initiatePayment', () {
      stateTest<PaymentController, PaymentState>(
        'emits loading then success with calculated fee',
        // Setup — only what THIS test needs
        setUp: () {
          paymentRepository = MockPaymentRepository();
          feeCalculator = FeeCalculator();

          when(() => paymentRepository.create(any()))
              .thenAnswer((_) async {});
        },
        build: () => PaymentController(
          paymentRepository: paymentRepository,
          feeCalculator: feeCalculator,
        ),
        act: (controller) => controller.initiatePayment(500),
        expect: () => [
          // Explicit expected states — the business rule is visible
          const PaymentState(status: LoadStatus.loading),
          PaymentState(
            status: LoadStatus.loaded,
            payment: createTestPayment(
              amount: 500,
              fee: 7.5, // 500 * 0.015 — standard rate
            ),
          ),
        ],
      );

      stateTest<PaymentController, PaymentState>(
        'applies volume discount for amounts over 10,000',
        // Similar setup? Yes. But this test tells its OWN story.
        setUp: () {
          paymentRepository = MockPaymentRepository();
          feeCalculator = FeeCalculator();

          when(() => paymentRepository.create(any()))
              .thenAnswer((_) async {});
        },
        build: () => PaymentController(
          paymentRepository: paymentRepository,
          feeCalculator: feeCalculator,
        ),
        act: (controller) => controller.initiatePayment(15000),
        expect: () => [
          const PaymentState(status: LoadStatus.loading),
          PaymentState(
            status: LoadStatus.loaded,
            payment: createTestPayment(
              amount: 15000,
              fee: 150, // 15,000 * 0.01 — volume discount
            ),
          ),
        ],
      );

      stateTest<PaymentController, PaymentState>(
        'emits error when repository fails',
        // Different setup — failure scenario is explicit
        setUp: () {
          paymentRepository = MockPaymentRepository();
          feeCalculator = FeeCalculator();

          when(() => paymentRepository.create(any()))
              .thenThrow(Exception('Network error'));
        },
        build: () => PaymentController(
          paymentRepository: paymentRepository,
          feeCalculator: feeCalculator,
        ),
        act: (controller) => controller.initiatePayment(500),
        expect: () => [
          const PaymentState(status: LoadStatus.loading),
          const PaymentState(
            status: LoadStatus.error,
            errorMessage: 'Failed to initiate payment',
          ),
        ],
      );
    });
  });

  group('WalletOverviewController', () {
    stateTest<WalletOverviewController, WalletOverviewState>(
      'loads wallets successfully',
      // This test has its OWN setup — no shared state with PaymentController tests
      setUp: () {
        walletRepository = MockWalletRepository();
        final testWallet = createTestWallet(balance: 5000);

        when(() => walletRepository.getWallets(page: 0, pageSize: 20))
            .thenAnswer((_) async => [testWallet]);
      },
      build: () => WalletOverviewController(walletRepository),
      act: (controller) => controller.loadWallets(),
      expect: () => [
        const WalletOverviewState(status: LoadStatus.loading),
        isA<WalletOverviewState>()
            .having((s) => s.status, 'status', LoadStatus.loaded)
            .having((s) => s.wallets.length, 'wallet count', 1),
      ],
    );
  });
}

// Each test is self-contained:
// 1. setUp shows preconditions (which mocks, what behavior)
// 2. build shows dependencies (only what's needed)
// 3. act shows the trigger
// 4. expect shows the expected outcome
// No cross-test dependencies, no shared mutable state.
