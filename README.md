### Steps to reproduce

1. Run MariaDB
For example, in docker:
```shell
docker run -d --rm -p 3306:3306 -e "MARIADB_ROOT_PASSWORD=123456" -e "MARIADB_ROOT_HOST=%" -e "MARIADB_DATABASE=migrationstest" mariadb:11.8
```

2. Make migrations
```shell
DB_CONNECTION_STRING="mysql://root:123456@127.0.0.1:3306/migrationstest" uv run tortoise makemigrations
```

2. Try to migrate
```shell
DB_CONNECTION_STRING="mysql://root:123456@127.0.0.1:3306/migrationstest" uv run tortoise migrate
```
