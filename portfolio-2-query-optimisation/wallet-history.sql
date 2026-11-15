-- Run after Portfolio 1 schema in a fresh database. Roll back the benchmark.
BEGIN;
INSERT INTO customers (display_name) VALUES ('Benchmark customer');
INSERT INTO wallets (customer_id)
SELECT customer_id FROM customers CROSS JOIN generate_series(1, 1000)
WHERE display_name = 'Benchmark customer';

WITH wallet_ids AS (
    SELECT array_agg(wallet_id ORDER BY wallet_id) AS ids
    FROM wallets JOIN customers USING (customer_id)
    WHERE display_name = 'Benchmark customer'
)
INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo, created_at)
SELECT ids[1 + (n % 1000)], ids[1 + ((n + 1) % 1000)], 'benchmark-' || n,
       10000 + n, TIMESTAMPTZ '2026-01-01 00:00+00' + n * INTERVAL '1 minute'
FROM wallet_ids CROSS JOIN generate_series(1, 100000) AS sample(n);
ANALYZE transfers;

\echo BEFORE INDEX
EXPLAIN (ANALYZE, BUFFERS)
SELECT transfer_id, destination_wallet_id, amount_kobo, created_at
FROM transfers
WHERE source_wallet_id = (SELECT source_wallet_id FROM transfers WHERE request_reference = 'benchmark-1')
ORDER BY created_at DESC, transfer_id DESC
LIMIT 10;

CREATE INDEX transfers_sent_history_idx
ON transfers (source_wallet_id, created_at DESC, transfer_id DESC);

\echo AFTER INDEX
EXPLAIN (ANALYZE, BUFFERS)
SELECT transfer_id, destination_wallet_id, amount_kobo, created_at
FROM transfers
WHERE source_wallet_id = (SELECT source_wallet_id FROM transfers WHERE request_reference = 'benchmark-1')
ORDER BY created_at DESC, transfer_id DESC
LIMIT 10;

SELECT request_reference, amount_kobo, created_at
FROM transfers
WHERE source_wallet_id = (SELECT source_wallet_id FROM transfers WHERE request_reference = 'benchmark-1')
ORDER BY created_at DESC, transfer_id DESC
LIMIT 10;
ROLLBACK;
