#!/bin/bash

USE_PERSISTENT_CONTAINERS="1"
#TORTOISE_PACKAGE="git+https://github.com/RuslanUC/tortoise-orm.git@develop"
#TORTOISE_PACKAGE="git+https://github.com/RuslanUC/tortoise-orm.git@fix-migrations-on-mariadb-use-placeholders"
#TORTOISE_PACKAGE="git+https://github.com/RuslanUC/tortoise-orm.git@fix-migrations-on-mariadb-replace-tzinfo"
TORTOISE_PACKAGE="git+https://github.com/RuslanUC/tortoise-orm.git@fix-migrations-on-mariadb-use-pypika"

CONTAINER_NAME_MARIADB="tortoiseorm-migration-test-mariadb"
CONTAINER_NAME_MYSQL="tortoiseorm-migration-test-mysql"
CONTAINER_NAME_POSTGRES="tortoiseorm-migration-test-postgres"

if [ "$USE_PERSISTENT_CONTAINERS" = "1" ]; then
  docker inspect "$CONTAINER_NAME_MARIADB" >/dev/null || \
    docker run -d --rm -p 3306:3306 -e "MARIADB_ROOT_PASSWORD=123456" -e "MARIADB_ROOT_HOST=%" -e "MARIADB_DATABASE=migrationstest" --name "$CONTAINER_NAME_MARIADB" mariadb:11.8
  docker inspect "$CONTAINER_NAME_MYSQL" >/dev/null || \
    docker run -d --rm -p 3307:3307 -e "MYSQL_ROOT_PASSWORD=123456" -e "MYSQL_ROOT_HOST=%" -e "MYSQL_DATABASE=migrationstest" -e "MYSQL_TCP_PORT=3307" --name "$CONTAINER_NAME_MYSQL" mysql:8
  docker inspect "$CONTAINER_NAME_POSTGRES" >/dev/null || \
    docker run -d --rm -p 5432:5432 -e "POSTGRES_PASSWORD=123456" -e "POSTGRES_DB=migrationstest" --name "$CONTAINER_NAME_POSTGRES" postgres:14.20-trixie
else
  echo "Will remove '$CONTAINER_NAME_MARIADB', '$CONTAINER_NAME_MYSQL' and '$CONTAINER_NAME_POSTGRES' docker containers! Type 'yes' to continue:"
  read yesorno
  if [ "$yesorno" != "yes" ]; then
      exit 1;
  fi

  docker rm -f  "$CONTAINER_NAME_MARIADB" "$CONTAINER_NAME_MARIADB" "$CONTAINER_NAME_POSTGRES"

  docker run -d --rm -p 3306:3306 -e "MARIADB_ROOT_PASSWORD=123456" -e "MARIADB_ROOT_HOST=%" -e "MARIADB_DATABASE=migrationstest" --name "$CONTAINER_NAME_MARIADB" mariadb:11.8
  docker run -d --rm -p 3307:3307 -e "MYSQL_ROOT_PASSWORD=123456" -e "MYSQL_ROOT_HOST=%" -e "MYSQL_DATABASE=migrationstest" -e "MYSQL_TCP_PORT=3307" --name "$CONTAINER_NAME_MYSQL" mysql:8
  docker run -d --rm -p 5432:5432 -e "POSTGRES_PASSWORD=123456" -e "POSTGRES_DB=migrationstest" --name "$CONTAINER_NAME_POSTGRES" postgres:14.20-trixie
fi

until mysqladmin ping -h 127.0.0.1 -u root -p123456 --port 3306 2>/dev/null
do
    echo "Waiting for mariadb server..."
    sleep 1
done

until mysqladmin ping -h 127.0.0.1 -u root -p123456 --port 3307 2>/dev/null
do
    echo "Waiting for mysql server..."
    sleep 1
done

until pg_isready -h 127.0.0.1 -U postgres -d migrationstest 2>/dev/null
do
    echo "Waiting for postgresql server..."
    sleep 1
done

rm -f test.db

mysql -h 127.0.0.1 --port 3306 -u root -p123456 migrationstest -e "DROP TABLE IF EXISTS somemodel; DROP TABLE IF EXISTS tortoise_migrations;"
mysql -h 127.0.0.1 --port 3307 -u root -p123456 migrationstest -e "DROP TABLE IF EXISTS somemodel; DROP TABLE IF EXISTS tortoise_migrations;"
PGPASSWORD=123456 psql -h 127.0.0.1 -U postgres -d migrationstest -c "DROP TABLE IF EXISTS somemodel; DROP TABLE IF EXISTS tortoise_migrations;"

uv sync
uv remove tortoise-orm && uv add "${TORTOISE_PACKAGE}[asyncpg,asyncmy,accel]"
DB_CONNECTION_STRING="mysql://root:123456@127.0.0.1:3306/migrationstest" uv run tortoise makemigrations

echo "Mariadb..."
DB_CONNECTION_STRING="mysql://root:123456@127.0.0.1:3306/migrationstest" uv run tortoise migrate
echo "Mysql..."
DB_CONNECTION_STRING="mysql://root:123456@127.0.0.1:3307/migrationstest" uv run tortoise migrate
echo "Postgres..."
DB_CONNECTION_STRING="postgres://postgres:123456@127.0.0.1/migrationstest" uv run tortoise migrate
echo "Sqlite..."
DB_CONNECTION_STRING="sqlite://test.db" uv run tortoise migrate

if [ "$USE_PERSISTENT_CONTAINERS" != "1" ]; then
  docker rm -f  "$CONTAINER_NAME_MARIADB" "$CONTAINER_NAME_MARIADB" "$CONTAINER_NAME_POSTGRES"
fi