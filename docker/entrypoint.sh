#!/bin/sh
set -e

echo "ServerName localhost" >> /etc/apache2/apache2.conf

cd /var/www/html

# Якщо Evolution ще не залитий у volume
if [ ! -d core ] || [ ! -f index.php ]; then
  echo "🚀 Downloading Evolution CMS into /var/www/html ..."

  # Перевірка, що папка справді пуста (окрім, можливо, .git, .gitignore)
  if [ "$(ls -A . 2>/dev/null | grep -v -E '^\.git$|^\.gitignore$')" ]; then
    echo "❌ /var/www/html is not empty. Content:"
    ls -A .
    echo "   👉 Або почисти volume 'evo_app', або поклади Evo-файли сам."
    exit 1
  fi

  composer create-project evolutioncms/evolution . --no-dev --no-interaction --remove-vcs

  if [ ! -d core ] || [ ! -f index.php ]; then
    echo "❌ Evolution download failed (core/ or index.php missing)"
    exit 1
  fi

  echo "🎉 Evolution CMS files downloaded. Далі — web installer /install."
else
  echo "ℹ️ Evolution files already present — skipping download."
fi

exec apache2-foreground