from datetime import datetime
from os import environ

from tortoise import fields, Model


class SomeModel(Model):
    id: int = fields.BigIntField(pk=True)
    dt: datetime = fields.DatetimeField()


TORTOISE_ORM = {
    "connections": {
        "default": environ["DB_CONNECTION_STRING"],
    },
    "apps": {
        "models": {
            "models": ["main"],
            "default_connection": "default",
            "migrations": "migrations",
        },
    },
}
