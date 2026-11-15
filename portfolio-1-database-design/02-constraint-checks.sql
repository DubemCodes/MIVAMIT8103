-- Run after 01-schema.sql in the same database.
-- The outer rollback removes all test rows. Identity values may advance.
BEGIN;

DO $$
DECLARE
    sender_customer bigint;
    recipient_customer bigint;
    sender_wallet bigint;
    recipient_wallet bigint;
    missing_wallet bigint := -1;
    test_reference text := 'portfolio-1-check-' || txid_current()::text;
    transfer_status text;
    violated_constraint text;
BEGIN
    INSERT INTO customers (display_name) VALUES ('Sample Sender')
    RETURNING customer_id INTO sender_customer;
    INSERT INTO customers (display_name) VALUES ('Sample Recipient')
    RETURNING customer_id INTO recipient_customer;

    INSERT INTO wallets (customer_id, balance_kobo) VALUES (sender_customer, 1000000)
    RETURNING wallet_id INTO sender_wallet;
    INSERT INTO wallets (customer_id, balance_kobo) VALUES (recipient_customer, 200000)
    RETURNING wallet_id INTO recipient_wallet;

    INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo)
    VALUES (sender_wallet, recipient_wallet, test_reference, 300000)
    RETURNING status INTO transfer_status;
    IF transfer_status IS DISTINCT FROM 'pending' THEN
        RAISE EXCEPTION 'A new transfer must default to pending';
    END IF;
    RAISE NOTICE 'PASS: valid ₦3,000 transfer recorded as pending';

    BEGIN
        INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo)
        VALUES (sender_wallet, sender_wallet, test_reference || '-self', 300000);
        RAISE EXCEPTION 'Expected the self-transfer to fail';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'transfers_distinct_wallets' THEN
            RAISE;
        END IF;
        RAISE NOTICE 'PASS: self-transfer rejected by %', violated_constraint;
    END;

    BEGIN
        INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo)
        VALUES (sender_wallet, recipient_wallet, test_reference, 300000);
        RAISE EXCEPTION 'Expected the duplicate reference to fail';
    EXCEPTION WHEN unique_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'transfers_reference_unique' THEN
            RAISE;
        END IF;
        RAISE NOTICE 'PASS: duplicate reference rejected by %', violated_constraint;
    END;

    BEGIN
        INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo)
        VALUES (sender_wallet, missing_wallet, test_reference || '-unknown', 300000);
        RAISE EXCEPTION 'Expected the unknown wallet to fail';
    EXCEPTION WHEN foreign_key_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'transfers_destination_fk' THEN
            RAISE;
        END IF;
        RAISE NOTICE 'PASS: unknown destination wallet rejected by %', violated_constraint;
    END;

    BEGIN
        INSERT INTO transfers (source_wallet_id, destination_wallet_id, request_reference, amount_kobo)
        VALUES (sender_wallet, recipient_wallet, test_reference || '-zero', 0);
        RAISE EXCEPTION 'Expected the zero amount to fail';
    EXCEPTION WHEN check_violation THEN
        GET STACKED DIAGNOSTICS violated_constraint = CONSTRAINT_NAME;
        IF violated_constraint <> 'transfers_positive_amount' THEN
            RAISE;
        END IF;
        RAISE NOTICE 'PASS: zero transfer amount rejected by %', violated_constraint;
    END;
END;
$$;

ROLLBACK;
