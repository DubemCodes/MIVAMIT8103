-- Install once after the Portfolio 1 schema.
CREATE FUNCTION post_transfer(request_id bigint) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    requested transfers%ROWTYPE;
BEGIN
    SELECT * INTO STRICT requested FROM transfers
    WHERE transfer_id = request_id FOR UPDATE;
    IF requested.status = 'completed' THEN
        RETURN;
    END IF;
    IF requested.status <> 'pending' THEN
        RAISE EXCEPTION 'Transfer % is not pending', request_id;
    END IF;

    -- Lock both wallets in a consistent order even for transfers in opposite directions.
    PERFORM wallet_id FROM wallets
    WHERE wallet_id IN (requested.source_wallet_id, requested.destination_wallet_id)
    ORDER BY wallet_id FOR UPDATE;

    UPDATE wallets SET balance_kobo = balance_kobo - requested.amount_kobo
    WHERE wallet_id = requested.source_wallet_id
      AND balance_kobo >= requested.amount_kobo;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Insufficient funds for transfer %', request_id;
    END IF;
    UPDATE wallets SET balance_kobo = balance_kobo + requested.amount_kobo
    WHERE wallet_id = requested.destination_wallet_id;

    INSERT INTO ledger_entries (transfer_id, direction, wallet_id)
    VALUES (request_id, 'debit', requested.source_wallet_id),
           (request_id, 'credit', requested.destination_wallet_id);

    UPDATE transfers SET status = 'completed' WHERE transfer_id = request_id;
END;
$$;
