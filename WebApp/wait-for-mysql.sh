#!/bin/sh
echo "⌛ Waiting for MySQL to be ready..."
while ! nc -z mysql 3306; do
  echo "⌛ MySQL not ready yet..."
  sleep 2
done
echo "✅ MySQL is ready!"
exec "$@"

