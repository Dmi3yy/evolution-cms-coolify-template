#!/bin/bash
set -e

echo "ServerName localhost" >> /etc/apache2/apache2.conf

# чек БД
echo "⏳ Waiting for PostgreSQL at $DB_HOST:$DB_PORT…"
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME"; do
  sleep 1
done
echo "✅ PostgreSQL ready"

cd /var/www/html

# якщо Evolution CMS НЕ встановлений
if [ ! -f core/factory/version.php ]; then
  echo "🚀 Installing Evolution CMS..."

  composer create-project evolutioncms/evolution .

  cd install
  php cli-install.php \
    --typeInstall=1 \
    --databaseType=pgsql \
    --databaseServer="$DB_HOST" \
    --databasePort="$DB_PORT" \
    --database="$DB_DATABASE" \
    --databaseUser="$DB_USERNAME" \
    --databasePassword="$DB_PASSWORD" \
    --tablePrefix="${EVO_TABLE_PREFIX:-evo_}" \
    --cmsAdmin="${EVO_ADMIN_LOGIN:-admin}" \
    --cmsAdminEmail="${EVO_ADMIN_EMAIL:-admin@example.com}" \
    --cmsPassword="${EVO_ADMIN_PASSWORD:-admin123}" \
    --language="${EVO_LANGUAGE:-en}" \
    --removeInstall=y

  cd ../core
  php artisan package:create "${EVO_MAIN_PACKAGE_NAME:-main}"
  echo "<?php return \"EvolutionCMS\\${EVO_MAIN_PACKAGE_NAME:-main}\\Controllers\\\";" \
    > custom/config/cms/settings/ControllerNamespace.php

  echo "🎉 Evolution CMS installed!"
else
  echo "ℹ️ Evolution already installed — skipping installer."
fi

exec apache2-foreground