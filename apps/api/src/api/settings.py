"""Configuration, from the environment."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="API_", env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://kino:kino@127.0.0.1:5432/kino"
    vod_grpc_target: str = "127.0.0.1:50051"
    host: str = "127.0.0.1"
    port: int = 8020


settings = Settings()
