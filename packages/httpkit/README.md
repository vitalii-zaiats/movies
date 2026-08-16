# httpkit

The HTTP client the scrapers share: rotating proxies and retries on the statuses
that mean "slow down". Nothing site-specific lives here.

```python
from httpkit import build_client, resolve_pool

pool = resolve_pool("http://user:pass@gate.provider.com:7000")
with build_client(headers=HEADERS, timeout=20, proxy=pool) as client:
    client.get(url)
```

## Proxy spec

| form                                   | meaning                                   |
|----------------------------------------|-------------------------------------------|
| `http://user:pass@gate.example.com:7000` | one gateway — the provider rotates the IP |
| `http://a:8000,http://b:8000`            | a list, used round-robin                  |
| `@proxies.txt`                           | one URL per line, `#` comments allowed    |

`resolve_pool(spec)` takes the flag value first and falls back to the `PROXY_URL`
environment variable, so you can export it once instead of passing it to every
command.

## Retries

`RetryingTransport` sits under the client, so every call site gets this for free:

- retries `408, 425, 429, 500, 502, 503, 504` and transport errors, 3 times by default;
- honours `Retry-After` when the server sends a number of seconds;
- otherwise backs off exponentially (1s, 2s, 4s…, capped at 30s) with jitter, so
  parallel workers don't all come back at the same moment;
- takes the **next proxy** on each attempt, so a retry leaves the address that
  was just refused.

Keep-alive is switched off whenever a proxy is configured: a rotating gateway
gives out a new exit IP per connection, and reusing the connection would pin you
to the one that just got rate-limited.
