#!/bin/sh
set -e

echo "ServerName localhost" >> /etc/apache2/apache2.conf

# ====== DB defaults ======
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"

# DB_NAME може прийти з env, але по дефолту "evo"
DB_NAME="${DB_NAME:-evo}"

# якщо DB_DATABASE не заданий — беремо DB_NAME
DB_DATABASE="${DB_DATABASE:-$DB_NAME}"

# юзер/пароль з env або дефолти
DB_USERNAME="${DB_USERNAME:-evo}"
DB_PASSWORD="${DB_PASSWORD:-pass}"

EVO_TABLE_PREFIX="${EVO_TABLE_PREFIX:-evo_}"
EVO_ADMIN_LOGIN="${EVO_ADMIN_LOGIN:-admin}"
EVO_ADMIN_EMAIL="${EVO_ADMIN_EMAIL:-admin@example.com}"
EVO_ADMIN_PASSWORD="${EVO_ADMIN_PASSWORD:-admin123}"
EVO_LANGUAGE="${EVO_LANGUAGE:-en}"
EVO_MAIN_PACKAGE_NAME="${EVO_MAIN_PACKAGE_NAME:-main}"

echo "🔧 DB config:"
echo "   host:     $DB_HOST"
echo "   port:     $DB_PORT"
echo "   database: $DB_DATABASE"
echo "   user:     $DB_USERNAME"

# ====== чек БД ======
echo "⏳ Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}…"
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
  sleep 1
done
echo "✅ PostgreSQL ready"

cd /var/www/html

# ====== інсталяція Evolution ======
if [ ! -f core/factory/version.php ]; then
  echo "🚀 Installing Evolution CMS..."

  # перший запуск: volume має бути ПУСТИЙ
  if [ "$(ls -A . 2>/dev/null)" ]; then
    echo "❌ /var/www/html is not empty, but Evolution is not installed."
    echo "   Content:"
    ls -A .
    echo "   👉 Швидше за все, це залишки попередніх спроб. Видали volume 'evo_app' і деплой заново."
    exit 1
  fi

  composer create-project evolutioncms/evolution . --no-dev --no-interaction --remove-vcs

  if [ ! -f core/factory/version.php ]; then
    echo "❌ Evolution install failed: core/factory/version.php not found"
    exit 1
  fi

  cd install
  echo "▶ Running cli-install.php..."
  php cli-install.php \
    --typeInstall=1 \
    --databaseType=pgsql \
    --databaseServer="$DB_HOST" \
    --databasePort="$DB_PORT" \
    --database="$DB_DATABASE" \
    --databaseUser="$DB_USERNAME" \
    --databasePassword="$DB_PASSWORD" \
    --tablePrefix="$EVO_TABLE_PREFIX" \
    --cmsAdmin="$EVO_ADMIN_LOGIN" \
    --cmsAdminEmail="$EVO_ADMIN_EMAIL" \
    --cmsPassword="$EVO_ADMIN_PASSWORD" \
    --language="$EVO_LANGUAGE" \
    --removeInstall=y

  cd ../core
  php artisan package:create "$EVO_MAIN_PACKAGE_NAME"

  cat > custom/config/cms/settings/ControllerNamespace.php <<EOF
<?php return "EvolutionCMS\\${EVO_MAIN_PACKAGE_NAME}\\Controllers\\";
EOF

  echo "🎉 Evolution CMS installed!"
else
  echo "ℹ️ Evolution already installed — skipping installer."
fi

exec apache2-foreground