# SOLID Violations — BAD/GOOD Examples

The examples use Dart; the language is only illustrative. The order and shipping domain is an example, not a requirement. Dependencies are passed through constructors here; in a real project, wire them the way the codebase already does (DI container, provider system, composition root).

## SRP — Single Responsibility Principle

### Violation: OrderController does too much

```dart
// BAD — One class handles order state AND notification sending
// Two reasons to change: order logic changes, or notification channel changes
class OrderController {
  OrderController(this._api, this._push, this._http);

  final OrderApi _api;
  final PushClient _push;
  final HttpClient _http;

  Order? current;

  Future<void> completeOrder(String orderId) async {
    final order = await _api.completeOrder(orderId);

    // Order logic
    current = order;

    // Notification logic — a different responsibility
    await _push.send(
      title: 'Order completed',
      body: 'Your order ${order.number} is complete.',
    );

    await _http.post(
      'https://chat.example.com/webhook',
      body: {'text': 'Order ${order.id} completed'},
    );
  }
}

// GOOD — Separate responsibilities into separate classes
class OrderController {
  OrderController(this._api, this._notifications);

  final OrderApi _api;
  final OrderNotificationService _notifications;

  Order? current;

  Future<void> completeOrder(String orderId) async {
    final order = await _api.completeOrder(orderId);
    current = order;

    // Notification is delegated — not this class's responsibility
    await _notifications.notifyOrderCompleted(order);
  }
}

// Notification is its own responsibility
class OrderNotificationService {
  OrderNotificationService(this._push);

  final PushClient _push;

  Future<void> notifyOrderCompleted(Order order) async {
    await _push.send(
      title: 'Order completed',
      body: 'Your order ${order.number} is complete.',
    );
  }
}
```

**Why:** The BAD version changes when order rules change AND when notification channels change. The GOOD version separates these: `OrderController` manages order state, `OrderNotificationService` handles notification delivery.

---

## OCP — Open/Closed Principle

### Violation: Switch statement for shipping carriers

```dart
// BAD — Adding a new carrier requires modifying this class
class ShipmentTracker {
  Future<TrackingInfo> track(Shipment shipment) async {
    switch (shipment.carrier) {
      case Carrier.carrierA:
        final client = CarrierAClient();
        return await client.getStatus(shipment.trackingCode);

      case Carrier.carrierB:
        final client = CarrierBClient();
        return await client.fetchTracking(shipment.externalId);

      // Every new carrier = modify this class + add a new case
      default:
        throw UnimplementedError('Carrier ${shipment.carrier} not supported');
    }
  }
}

// GOOD — New carriers are extensions, not modifications
abstract class CarrierTrackingAdapter {
  Carrier get carrier;
  Future<TrackingInfo> track(Shipment shipment);
}

class CarrierATrackingAdapter implements CarrierTrackingAdapter {
  CarrierATrackingAdapter(this._client);

  final CarrierAClient _client;

  @override
  Carrier get carrier => Carrier.carrierA;

  @override
  Future<TrackingInfo> track(Shipment shipment) =>
      _client.getStatus(shipment.trackingCode);
}

class CarrierBTrackingAdapter implements CarrierTrackingAdapter {
  CarrierBTrackingAdapter(this._client);

  final CarrierBClient _client;

  @override
  Carrier get carrier => Carrier.carrierB;

  @override
  Future<TrackingInfo> track(Shipment shipment) =>
      _client.fetchTracking(shipment.externalId);
}

// The tracker picks an adapter — adding a carrier = adding a class and registering it
class ShipmentTracker {
  ShipmentTracker(this._adapters);

  final List<CarrierTrackingAdapter> _adapters;

  Future<TrackingInfo> track(Shipment shipment) {
    final adapter = _adapters.firstWhere((a) => a.carrier == shipment.carrier);
    return adapter.track(shipment);
  }
}
```

**Why:** The BAD version requires modifying `ShipmentTracker` every time a carrier is added. The GOOD version is closed for modification: add a new `CarrierTrackingAdapter` implementation and register it wherever the codebase wires its dependencies.

---

## LSP — Liskov Substitution Principle

### Violation: Data source that doesn't fulfill the contract

```dart
// BAD — ReadOnlyOrderDataSource violates the OrderDataSource contract
abstract class OrderDataSource {
  Future<Order> getById(String id);
  Future<void> update(Order order);
  Future<void> delete(String id);
}

class ReadOnlyOrderDataSource implements OrderDataSource {
  ReadOnlyOrderDataSource(this._http);

  final HttpClient _http;

  @override
  Future<Order> getById(String id) async {
    final json = await _http.getJson('/orders/$id');
    return Order.fromJson(json);
  }

  @override
  Future<void> update(Order order) =>
      throw UnimplementedError('Read-only data source'); // LSP violation!

  @override
  Future<void> delete(String id) =>
      throw UnsupportedError('Read-only data source'); // LSP violation!
}

// GOOD — Segregate the interface (ISP + LSP working together)
abstract class OrderReader {
  Future<Order> getById(String id);
}

abstract class OrderWriter {
  Future<void> update(Order order);
  Future<void> delete(String id);
}

// Full data source implements both
class HttpOrderDataSource implements OrderReader, OrderWriter {
  HttpOrderDataSource(this._http);

  final HttpClient _http;

  @override
  Future<Order> getById(String id) async {
    final json = await _http.getJson('/orders/$id');
    return Order.fromJson(json);
  }

  @override
  Future<void> update(Order order) => _http.put('/orders/${order.id}', order.toJson());

  @override
  Future<void> delete(String id) => _http.delete('/orders/$id');
}

// Read-only consumers depend only on OrderReader — no surprise exceptions
class OrderDetailsController {
  OrderDetailsController(this._reader); // Only what it needs

  final OrderReader _reader;

  Future<Order> load(String orderId) => _reader.getById(orderId);
}
```

**Why:** The BAD version throws for methods it can't support; any code that calls `update` on what it thinks is a valid `OrderDataSource` will crash. The GOOD version splits the interface so read-only consumers never see write methods.

---

## ISP — Interface Segregation Principle

### Violation: Fat booking service interface

```dart
// BAD — One abstract class forces all implementors to support everything
abstract class BookingService {
  Future<List<Slot>> searchSlots(DateRange range);
  Future<Booking> createBooking(String slotId, String userId);
  Future<void> cancelBooking(String bookingId);
  Future<Payment> processPayment(String bookingId, PaymentMethod method);
  Future<void> sendReceipt(String bookingId, String email);
  Future<List<Booking>> getHistory(String userId);
  Future<void> reportIssue(String bookingId, String description);
}

// The search screen only needs slot search — forced to depend on payments, history, etc.
class SlotSearchController {
  SlotSearchController(this._service); // Depends on 7 methods, uses 1

  final BookingService _service;

  Future<List<Slot>> search(DateRange range) => _service.searchSlots(range);
}

// GOOD — Segregated by client need
abstract class SlotFinder {
  Future<List<Slot>> searchSlots(DateRange range);
}

abstract class BookingManager {
  Future<Booking> createBooking(String slotId, String userId);
  Future<void> cancelBooking(String bookingId);
}

abstract class BookingPaymentProcessor {
  Future<Payment> processPayment(String bookingId, PaymentMethod method);
  Future<void> sendReceipt(String bookingId, String email);
}

abstract class BookingHistoryReader {
  Future<List<Booking>> getHistory(String userId);
}

// The search screen depends only on what it uses
class SlotSearchController {
  SlotSearchController(this._finder);

  final SlotFinder _finder;

  Future<List<Slot>> search(DateRange range) => _finder.searchSlots(range);
}
```

**Why:** The BAD version forces every consumer to depend on all booking operations. When payment logic changes, `SlotSearchController` must be reanalyzed even though it never uses payments. The GOOD version lets each consumer depend only on the operations it needs.

---

## DIP — Dependency Inversion Principle

### Violation: Business logic depends on concrete infrastructure

```dart
// BAD — Directly constructs and calls concrete infrastructure
class AccountRegistration {
  Future<Account> register(String email) async {
    // Concrete types created inline — untestable, tightly coupled
    final http = HttpClient(baseUrl: 'https://api.example.com');
    final json = await http.postJson('/accounts', {'email': email});
    final account = Account.fromJson(json);

    final storage = await LocalKeyValueStore.open();
    await storage.setString('last_account_id', account.id);

    await PushClient.instance.subscribeToTopic('account_${account.id}');

    return account;
  }
}

// GOOD — Depend on abstractions, injected from outside
abstract class AccountApi {
  Future<Account> register(String email);
}

abstract class AccountStorage {
  Future<void> saveLastAccountId(String accountId);
}

abstract class AccountNotificationSubscriber {
  Future<void> subscribeToAccount(String accountId);
}

class AccountRegistration {
  AccountRegistration(this._api, this._storage, this._subscriber);

  final AccountApi _api;
  final AccountStorage _storage;
  final AccountNotificationSubscriber _subscriber;

  Future<Account> register(String email) async {
    final account = await _api.register(email);
    await _storage.saveLastAccountId(account.id);
    await _subscriber.subscribeToAccount(account.id);
    return account;
  }
}
```

**Why:** The BAD version can't be tested without a real API server, local storage, and push service. The GOOD version depends on abstractions: swap in fakes for testing, swap implementations for different environments.
