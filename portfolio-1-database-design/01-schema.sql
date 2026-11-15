-- Run in a dedicated PostgreSQL training database.
BEGIN;

CREATE TABLE customers (
    customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    display_name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE wallets (
    wallet_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id bigint NOT NULL REFERENCES customers (customer_id),
    balance_kobo bigint NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT wallets_nonnegative_balance CHECK (balance_kobo >= 0)
);

CREATE TABLE transfers (
    transfer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_wallet_id bigint NOT NULL,
    destination_wallet_id bigint NOT NULL,
    request_reference text NOT NULL,
    amount_kobo bigint NOT NULL,
    status text NOT NULL DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT transfers_source_fk FOREIGN KEY (source_wallet_id) REFERENCES wallets (wallet_id),
    CONSTRAINT transfers_destination_fk FOREIGN KEY (destination_wallet_id) REFERENCES wallets (wallet_id),
    CONSTRAINT transfers_reference_unique UNIQUE (request_reference),
    CONSTRAINT transfers_reference_nonblank CHECK (btrim(request_reference) <> ''),
    CONSTRAINT transfers_distinct_wallets CHECK (source_wallet_id <> destination_wallet_id),
    CONSTRAINT transfers_positive_amount CHECK (amount_kobo > 0),
    CONSTRAINT transfers_valid_status CHECK (status IN ('pending', 'completed', 'failed'))
);

CREATE TABLE ledger_entries (
    transfer_id bigint NOT NULL REFERENCES transfers (transfer_id),
    direction text NOT NULL,
    wallet_id bigint NOT NULL REFERENCES wallets (wallet_id),
    posted_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ledger_entries_pk PRIMARY KEY (transfer_id, direction),
    CONSTRAINT ledger_entries_valid_direction CHECK (direction IN ('debit', 'credit'))
);

COMMIT;
