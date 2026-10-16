from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "InvenPilot API"
    app_version: str = "1.0.0"
    database_url: str = "postgresql+psycopg://invenpilot:invenpilot@localhost:5432/invenpilot"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
