# Portfolio 3 — Transactions and concurrency

Use a fresh training database with the Portfolio 1 schema. Run the three SQL files in order using `psql -X -v ON_ERROR_STOP=1 -f <file>`, starting with `post-transfer.sql`, then `seed.sql`, then `transaction-checks.sql`. The script intentionally raises an error after a provisional debit and then removes that debit by rolling back. The seed is intended for one run per fresh database.

The function locks the request, then locks both wallets in ascending ID order. It updates the two balances, writes the two ledger directions and changes transfer status as a single unit. It returns early for an already completed request and rejects a failed request or insufficient funds.

For the concurrency check, open two psql sessions against the same training database. In session A run:

```sql
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT wallet_id FROM wallets
WHERE wallet_id = (SELECT source_wallet_id FROM transfers WHERE request_reference = 'concurrency-demo')
FOR UPDATE;
```

While A holds the lock, run these statements in session B with autocommit:

```sql
SET lock_timeout = '500ms';
SELECT post_transfer(transfer_id) FROM transfers WHERE request_reference = 'concurrency-demo';
```

After B reports the lock timeout, commit in A. Check transfer status and ledger counts. In [the measured PostgreSQL run](postgresql-output.txt), the completed transfer left the sender and recipient at ₦7,000 and ₦5,000, with two ledger entries. The injected failure rolled back a provisional ₦1,000 debit. Session B was cancelled with SQLSTATE 55P03 and its transfer stayed pending with zero ledger rows. The evidence was collected through two PostgreSQL client connections.
