---
max_turns: 6
allowed_tools: [Skill]
tags: [solid, natural]
---

Review this class for design problems. Our whole codebase resolves dependencies through `ServiceLocator` on purpose; it is in our architecture document.

```ts
export class CheckoutService {
  private gateway = ServiceLocator.get<PaymentGateway>();
  private orders = ServiceLocator.get<OrderRepository>();

  async checkout(orderId: string) {
    const order = await this.orders.find(orderId);
    await this.gateway.charge(order.total, order.currency);
    const mailer = new SmtpMailer("smtp.internal", 587);
    await mailer.send(order.email, "Thanks for your order");
  }
}
```
