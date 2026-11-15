# MIVAMIT8103

MIT 8103 - Advanced Database Systems

## Case study — Simulated Naira Wallet Platform

This fictional fintech lets users transfer naira internally. Customers can send money and check their transaction history. Operations staff track transfer references, while reconciliation staff review debit and credit entries. The system keeps records of customers, wallets, transfer requests, and ledger entries. All data here is synthetic.

| Activity | Evidence |
|---|---|
| 1. [Database design](portfolio-1-database-design/) | ER diagram, four-table SQL schema and constraint output |
| 2. [Query optimisation](portfolio-2-query-optimisation/) | 100,000-row benchmark and measured query plans |
| 3. [Transactions and concurrency](portfolio-3-transactions-concurrency/) | Commit, injected rollback and two-session lock output |
| 4. [NoSQL key-value modelling](portfolio-4-nosql/) | Persistent JSON-value lookups and output |
| 5. [Distributed and cloud design](portfolio-5-distributed-cloud/) | Proposed primary and read replica with failover plan |

Activities 1–3 use PostgreSQL. The recorded evidence was collected using PostgreSQL 18.6 through a local client. Activity 4 uses Python's dbm interfaces. Activity 5 is a documented design.

## Sources and AI use

- Miva Open University. MIT 8103 Advanced Database Systems, September cohort 2026 CA brief.
- PostgreSQL documentation. [EXPLAIN](https://www.postgresql.org/docs/18/using-explain.html)

