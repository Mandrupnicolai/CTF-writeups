---
title: "SQLi in Search"
category: "Web"
difficulty: "Easy"
tags: ["sqli", "sqlite", "union-select", "error-leak"]
challenge: "challenges/web-sqli-search/app.py"
exploit: "exploits/exploit_sqli_search.py"
last_updated: "2026-03-23"
---

# Web: SQLi in Search

## Summary
Exploit a UNION-based SQL injection in a SQLite-backed search endpoint to read the `flags` table.

## Challenge
- Endpoint: `GET /search?q=<input>`
- Vulnerable query shape:
  ```sql
  SELECT title FROM posts WHERE title LIKE '%<q>%'
  ```
- App also echoes SQLite exceptions to the client (useful for discovery).

## Solution
Because `q` is interpolated into SQL without parameters, we can terminate the string and append a `UNION SELECT` that returns the flag.

### Steps
1. Confirm injection: `q=' OR 1=1 --` should return all posts.
2. Because the original query selects 1 column (`title`), use a 1-column UNION payload.
3. Extract flag: `q=' UNION SELECT flag FROM flags --`

## Reproduction
1. Run the challenge: `python challenges/web-sqli-search/app.py` (listens on `http://localhost:5002`).
2. Run the exploit: `python exploits/exploit_sqli_search.py`.

## Flag
`flag{union_select_ftw}`

## Mitigation
- Use parameterized queries (prepared statements), including for `LIKE` patterns.
- Do not return raw DB exceptions to users; log them server-side.

---
Ethics note: this writeup targets the intentionally vulnerable code in this repository only. Do not use these techniques on systems you do not own or have explicit permission to test.

