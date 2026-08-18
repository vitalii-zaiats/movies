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

    # Who may call this from another origin. The default is the wildcard, and
    # the wildcard deliberately means *no cookies* — see `main.create_app`.
    # Name your origins and the session cookie starts working cross-origin.
    cors_origins: list[str] = ["*"]

    # --- identity -----------------------------------------------------------
    # A guest *is* their token, so it has to outlive the browser session that
    # got it. Claiming an account doesn't shorten it: same row, same login.
    session_ttl_days: int = 365
    session_cookie: str = "kino_session"
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
