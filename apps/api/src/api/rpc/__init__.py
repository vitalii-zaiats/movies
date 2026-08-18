"""gRPC: a second way in, over the same services HTTP is served from.

Nothing in here decides anything. Every method opens a session, builds the
service graph out of `api.core.services`, calls one method on it and turns the
answer into a protobuf message — the same three steps `api.main`'s routes take
with JSON. A rule that holds in one layer therefore holds in the other, because
there is only one place it is written down.

    api.main  ──┐
                ├──►  api.core.services  ──►  modules/*/service.py
    api.rpc   ──┘

Run it with `uv run api-grpc`; it is a process of its own, not a thread inside
uvicorn, so one can be restarted, scaled or turned off without the other.
"""
