# Portfolio 3 — Transactions and concurrency

Start with a new training database that uses the Portfolio 1 schema. Run the three SQL files in order with psql -X -v ON_ERROR_STOP=1 -f <file>. Begin with post-transfer.sql, then run seed.sql, and finally transaction-checks.sql. The script will raise an error after a provisional debit and then roll back to remove it. Only run the seed once for each new database.

The function first locks the request, then locks both wallets by ascending ID. It updates both balances, records the two ledger entries, and changes the transfer status all at once. If the request is already completed, it returns early. It also rejects requests that have failed or do not have enough funds.

To check for concurrency, open two psql sessions connected to the same training database. In session A, run:

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
