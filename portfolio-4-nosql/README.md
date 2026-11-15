# Portfolio 4 — NoSQL key-value model

The lookup starts from a transfer reference. The key is `transfer:<reference>` and the value is a JSON document containing the reference and an ordered list of events. Event types have different fields. A requested event carries an amount and currency, a completed event carries a ledger count, and a failed posting attempt carries a reason.

Run `python3 transfer-events.py`. The implementation uses the Python standard library's dbm interface for a local persistent key-value store. It closes and reopens the store before looking up two transfer histories and an unknown reference. The [actual output](key-value-output.txt) identifies the selected backend and records the lookup checks.

A direct lookup reads one value and avoids joining multiple event tables. The model suits an operations view for a known transfer reference. Finding all failed attempts by date would require another access path. Updating an event list also rewrites the value, so longer histories and concurrent writers would need a different storage design. This local model experiments with event lookup. PostgreSQL continues to own balances and ledger postings.
