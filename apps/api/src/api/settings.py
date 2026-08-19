"""Configuration, from the environment."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="API_", env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://kino:kino@127.0.0.1:5432/kino"
    vod_grpc_target: str = "127.0.0.1:50051"
    # Where a browser reaches the VOD service. A path, not a host, so the whole
    # thing survives being put behind one tunnel or one nginx.
    vod_base: str = "/vod"
    host: str = "127.0.0.1"
    port: int = 8020
    # The other presentation layer, in its own process — see `api.rpc`. A port
    # of its own rather than a path on the first one: gRPC wants the whole
    # connection, and nginx would have to be taught h2c to share it.
    grpc_host: str = "127.0.0.1"
    grpc_port: int = 50061

    # TLS on that port. Paths to PEM files; unset means the port is plaintext,
    # which is what it should be when nginx terminates TLS in front of it and
    # the hop from there is inside a compose network.
    #
    # Set them when a device talks to this port directly — a phone on the LAN
    # has no nginx in the way, and a session token is a bearer token: whoever
    # reads it off the wire is that user until it expires.
    grpc_tls_cert: str | None = None
    grpc_tls_key: str | None = None
    # A CA to check *client* certificates against. Set it and the door opens
    # only for devices holding a certificate we signed — mutual TLS, on top of
    # the session token rather than instead of it.
    grpc_tls_client_ca: str | None = None

    # Who may call this from another origin. The default is the wildcard, and
    # the wildcard deliberately means *no cookies* — see `main.create_app`.
    # Name your origins and the session cookie starts working cross-origin.
    cors_origins: list[str] = ["*"]

    # --- identity -----------------------------------------------------------
    # A guest *is* their token, so it has to outlive the browser session that
    # got it. Claiming an account doesn't shorten it: same row, same login.
    session_ttl_days: int = 365
    session_cookie: str = "kino_session"
    # Where a phone goes to approve a television. A path, not a host, for the
    # same reason `vod_base` is one: the server doesn't know what address this
    # install is reached on, and whatever drew the QR does.
    link_base: str = "/link"
    # Off by default because the LAN stack is plain http behind nginx. Turn it
    # on the day this sits behind real TLS.
    session_cookie_secure: bool = False

    # --- uploads ------------------------------------------------------------
    # Where banners land. A volume in compose — the database keeps the row, the
    # disk keeps the bytes, and losing one without the other is a bad day.
    media_root: str = "data/media"
    # Where a browser reaches them. A path, not a host, for the same reason
    # `vod_base` is one.
    media_base: str = "/media"
    max_upload_bytes: int = 8 * 1024 * 1024

    # Optional shared secret for `POST /ingest/episodes`, sent as `X-Api-Key`.
    # Unset means the endpoint stays open, which is what the seeder expects on a
    # LAN. Set it and the endpoint takes that key or an admin session, nothing
    # else.
    ingest_token: str | None = None

    @property
    def session_ttl_seconds(self) -> int:
        return self.session_ttl_days * 24 * 60 * 60


settings = Settings()
