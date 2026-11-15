# Portfolio 4 — NoSQL key-value model

The lookup begins with a transfer reference. The key is `transfer:<reference>`, and its value is a JSON document that includes the reference and an ordered list of events. Each event type has its own fields. For example, a requested event includes an amount and currency, a completed event includes a ledger count, and a failed posting attempt includes a reason.

To use the script, run `python3 transfer-events.py`. The script relies on the Python standard library's dbm interface to provide a local persistent key-value store. It closes and reopens the store before checking two transfer histories and an unknown reference. The [actual output](key-value-output.txt) shows which backend was used and logs the lookup checks.

A direct lookup reads a single value and avoids joining multiple event tables. This model works well for viewing operations related to a specific transfer reference. To find all failed attempts by date, you would need a different access method. Updating an event list rewrites the value, so handling longer histories or multiple writers would require another storage approach. This local model is mainly for experimenting with event lookup. PostgreSQL still manages balances and ledger postings.
