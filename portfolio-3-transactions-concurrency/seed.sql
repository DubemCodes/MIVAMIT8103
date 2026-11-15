INSERT INTO customers (display_name) VALUES ('Demo sender'), ('Demo recipient');
INSERT INTO wallets (customer_id, balance_kobo)
SELECT customer_id, CASE display_name WHEN 'Demo sender' THEN 1000000 ELSE 200000 END
FROM customers WHERE display_name IN ('Demo sender', 'Demo recipient');
INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo)
SELECT sender.wallet_id, recipient.wallet_id, reference, amount
FROM wallets sender JOIN customers s ON s.customer_id = sender.customer_id
CROSS JOIN (wallets recipient JOIN customers r ON r.customer_id = recipient.customer_id)
CROSS JOIN (VALUES ('commit-demo', 300000), ('rollback-demo', 100000), ('concurrency-demo', 600000)) AS requests(reference, amount)
WHERE s.display_name = 'Demo sender' AND r.display_name = 'Demo recipient';
