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


settings = Settings()
