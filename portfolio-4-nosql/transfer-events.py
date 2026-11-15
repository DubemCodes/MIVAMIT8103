"""Persist and query synthetic wallet transfer events using a local key-value store."""

import dbm
import json
from pathlib import Path
from tempfile import TemporaryDirectory

EVENTS = {
    "commit-demo": [
        {"type": "requested", "amount_kobo": 300000, "currency": "NGN"},
        {"type": "completed", "ledger_entries": 2},
    ],
    "rollback-demo": [
        {"type": "requested", "amount_kobo": 100000, "currency": "NGN"},
        {"type": "posting_attempt_failed", "reason": "Injected failure after debit"},
    ],
}


def transfer_events(store, reference):
    value = store.get(f"transfer:{reference}")
    return json.loads(value)["events"] if value is not None else []


def main():
    with TemporaryDirectory() as directory:
        path = str(Path(directory) / "event-store")
        with dbm.open(path, "n") as store:
            for reference, events in EVENTS.items():
                document = {"reference": reference, "events": events}
                store[f"transfer:{reference}"] = json.dumps(document).encode("utf-8")
        print(f"Backend: {dbm.whichdb(path)}")
        with dbm.open(path, "r") as store:
            for reference, expected in EVENTS.items():
                actual = transfer_events(store, reference)
                if actual != expected:
                    raise AssertionError(f"Unexpected history for {reference}")
                print(reference, json.dumps(actual))
            if transfer_events(store, "unknown") != []:
                raise AssertionError("Unknown reference returned events")
            print("PASS: stored histories reopened and queried by reference")
            print("PASS: unknown reference returned an empty history")


if __name__ == "__main__":
    main()
