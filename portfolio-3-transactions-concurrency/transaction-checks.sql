\echo COMMIT
BEGIN ISOLATION LEVEL READ COMMITTED;
SHOW transaction_isolation;
SELECT post_transfer(transfer_id) FROM transfers WHERE request_reference = 'commit-demo';
COMMIT;

-- Raise an actual exception after a debit and roll back to the savepoint.
\echo ROLLBACK AFTER INJECTED FAILURE
BEGIN;
SAVEPOINT before_debit;
UPDATE wallets SET balance_kobo = balance_kobo - 100000
WHERE wallet_id = (SELECT source_wallet_id FROM transfers WHERE request_reference = 'rollback-demo')
RETURNING balance_kobo AS provisional_sender_balance;
\set ON_ERROR_STOP off
DO $$ BEGIN RAISE EXCEPTION 'Injected failure after debit'; END; $$;
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT before_debit;
ROLLBACK;

SELECT display_name, balance_kobo FROM wallets JOIN customers USING (customer_id) ORDER BY display_name;
SELECT request_reference, status, count(direction) AS ledger_entries
FROM transfers LEFT JOIN ledger_entries USING (transfer_id)
GROUP BY request_reference, status ORDER BY request_reference;
