# Sidra payments server

The Flutter app never holds the MarzPay secret. When a learner taps
**Pay with mobile money**, the app only asks PostgreSQL to queue a payment for
what they owe (`start_course_payment`). This server does the rest:

1. **Send.** It takes queued payments (`payments_api.claim`) and asks
   MarzPay to collect. MarzPay pushes a PIN prompt to the learner's phone.
   A PostgreSQL `NOTIFY` wakes it instantly; it also checks every 5 seconds.
2. **Confirm.** Every 20 seconds it asks MarzPay about payments still waiting
   (`GET /collect-money/{uuid}`). On success it records the payment as
   verified, which opens the course.
3. **Webhook (optional).** With `PUBLIC_URL` set, MarzPay calls
   `PUBLIC_URL/marzpay/webhook`. The body is never trusted: the server
   re-fetches the transaction from MarzPay before recording anything.

It also records MarzPay's fee (the debit that shares our reference), which
Finance subtracts when it works out Retained.

## Security

* It logs in as `sidra_payments`, which can only call `payments_api.*`. It
  cannot read learners, courses or payments.
* A crash can't prompt anyone twice. Each payment's MarzPay `reference` is
  fixed when it is created. If it is re-sent, MarzPay answers
  `DUPLICATE_REFERENCE` and the server looks the transaction up instead.
* Money is credited only for the exact amount asked. Any other amount is
  held for a finance officer to decide.

## Run it

```sh
dart run tool/db.dart payments-role   # once: creates the login, writes PAYMENTS_DATABASE_URL to .env
cd server && dart run bin/payments_server.dart
```

Environment (a real deployment sets these; `../.env` is read on a developer
machine):

| Variable | Meaning |
|---|---|
| `PAYMENTS_DATABASE_URL` | `sidra_payments` login on Neon's **direct** host (not `-pooler`), for LISTEN |
| `MARZPAY_API_KEY`, `MARZPAY_API_SECRET` | from the MarzPay dashboard (or `MARZPAY_AUTH_BASIC`) |
| `MARZPAY_BASE_URL` | default `https://wallet.wearemarz.com/api/v1` |
| `PUBLIC_URL` | optional HTTPS address of this server, for MarzPay webhooks |
| `PORT` | default 8080 |

`GET /health` returns the last queue and reconcile runs.

## Deploy

Any host that keeps one small process running works: a VPS, Fly.io,
Railway, or Render (paid instance, so it doesn't sleep). Use the
`Dockerfile`. Polling alone completes payments. Add `PUBLIC_URL` for
faster confirmation, and ask MarzPay to allow that address if they
require it. Run **one** instance.
