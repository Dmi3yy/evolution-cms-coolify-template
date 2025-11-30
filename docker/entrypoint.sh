#!/bin/sh
set -e

echo "ServerName localhost" >> /etc/apache2/apache2.conf

DB_PORT="${DB_PORT:-5432}"

# чек БД
echo "⏳ Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}…"
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
  sleep 1
done
echo "✅ PostgreSQL ready"

cd /var/www/html

# якщо Evolution CMS НЕ встановлений
if [ ! -f core/factory/version.php ]; then
  echo "🚀 Installing Evolution CMS..."

  echo "🧹 Cleaning webroot /var/www/html for fresh install..."
  # видаляємо ВСЕ в /var/www/html, але не саму директорію
  find . -mindepth 1 -maxdepth 1 -exec rm -rf {} \;

  # ставимо Evo в порожню папку
  composer create-project evolutioncms/evolution . --no-dev --no-interaction --remove-vcs

  # якщо раптом create-project не створив core/factory/version.php — вивалюємося
  if [ ! -f core/factory/version.php ]; then
    echo "❌ Evolution install failed: core/factory/version.php not found"
    exit 1
  fi

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

  cat > custom/config/cms/settings/ControllerNamespace.php <<EOF
<?php return "EvolutionCMS\\${EVO_MAIN_PACKAGE_NAME:-main}\\Controllers\\";
EOF

  echo "🎉 Evolution CMS installed!"
else
  echo "ℹ️ Evolution already installed — skipping installer."
fi

exec apache2-foreground