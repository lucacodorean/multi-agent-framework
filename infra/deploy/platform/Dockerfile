# syntax=docker/dockerfile:1.7
# Preview platform image — one image for Compose services `web` and `queue`.
#
# web  uses the default CMD (nginx + php-fpm, non-root, TLS :8443).
# queue overrides command to `php artisan queue:work --tries=1 --timeout=360`.
#
# Not ddev/ddev-webserver. Not a migrate/first-admin entrypoint (T6).
#
# Build from repository root:
#   docker build -f infra/deploy/platform/Dockerfile -t oir-flow-preview-platform:t3 .
#
# Pins (recorded 2026-08-17; do not float `latest`):
#   php:8.5.7-fpm-bookworm
#     digest sha256:8971d7dee33749d35c98ae465bfa769346961151a8c24a0a41c9713fcbc1f521
#     PHP 8.5.7 — same patch DDEV/CI run (infra/ci/platform-suite.sh).
#   node:22.21.0-bookworm-slim
#     digest sha256:f9f7f95dcf1f007b007c4dcd44ea8f7773f931b71dc79d57c216e731c87a090b
#   composer:2.8.10  (build stage only)
#     digest sha256:20462d70afcfa999ad75dbd9333194067f4d869078bdb37430339e8d97e541d6
#   pecl redis-6.3.0 (6.2.0 does not build on PHP 8.5)

FROM php:8.5.7-fpm-bookworm AS php-base

# Runtime libs stay; *-dev + $PHPIZE_DEPS are purged after the .so files link.
# opcache is compiled into this official image (php -m already lists it).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      $PHPIZE_DEPS \
      libpq-dev \
      libpq5 \
      libicu-dev \
      libicu72 \
      libzip-dev \
      libzip4 \
      libpng-dev \
      libpng16-16 \
      libjpeg62-turbo-dev \
      libjpeg62-turbo \
      libfreetype6-dev \
      libfreetype6 \
      libwebp-dev \
      libwebp7 \
 && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
 && docker-php-ext-install -j"$(nproc)" \
      pdo_pgsql \
      gd \
      intl \
      zip \
      bcmath \
      pcntl \
 && yes no | pecl install redis-6.3.0 \
 && docker-php-ext-enable redis \
 && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
      $PHPIZE_DEPS \
      libpq-dev \
      libicu-dev \
      libzip-dev \
      libpng-dev \
      libjpeg62-turbo-dev \
      libfreetype6-dev \
      libwebp-dev \
 && rm -rf /var/lib/apt/lists/* /tmp/pear

# Non-root master cannot setuid. Official www.conf hard-codes user/group=www-data.
RUN sed -i -E \
      -e 's/^user\s*=.*/;user = app (non-root master)/' \
      -e 's/^group\s*=.*/;group = app/' \
      /usr/local/etc/php-fpm.d/www.conf \
 && ! grep -E '^(user|group)\s*=' /usr/local/etc/php-fpm.d/www.conf

# -----------------------------------------------------------------------------
FROM php-base AS composer

COPY --from=composer:2.8.10 /usr/bin/composer /usr/bin/composer

RUN apt-get update \
 && apt-get install -y --no-install-recommends git unzip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer \
    APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr

COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/tmp/composer/cache \
    composer install \
      --no-dev \
      --no-scripts \
      --no-autoloader \
      --no-interaction \
      --no-progress \
      --prefer-dist

COPY artisan ./
COPY bootstrap/app.php bootstrap/providers.php ./bootstrap/
COPY app ./app
COPY config ./config
COPY database ./database
COPY public ./public
COPY resources ./resources
COPY routes ./routes

# filament:upgrade = filament:assets + cache clears. --no-scripts without this
# step is the 200-but-broken Filament UI footgun (public/js/filament empty).
RUN mkdir -p \
      bootstrap/cache \
      storage/framework/cache/data \
      storage/framework/sessions \
      storage/framework/views \
      storage/logs \
 && composer dump-autoload --optimize --no-dev --no-scripts \
 && php artisan package:discover --ansi \
 && php artisan filament:upgrade --ansi

# -----------------------------------------------------------------------------
FROM node:22.21.0-bookworm-slim AS assets

WORKDIR /var/www/html

# Repo .npmrc sets ignore-scripts=true (same as DDEV `npm install --ignore-scripts`).
# No package-lock.json is committed; npm ci cannot be used.
COPY package.json .npmrc vite.config.js ./
COPY resources ./resources

RUN mkdir -p public storage/framework/views \
 && npm install --ignore-scripts \
 && npm run build \
 && test -f public/build/manifest.json

# -----------------------------------------------------------------------------
FROM php-base AS runtime

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx openssl \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default \
 && useradd --uid 1000 --user-group --home-dir /var/www/html --shell /usr/sbin/nologin app \
 && mkdir -p /var/lib/oir-flow/tls \
 && chown app:app /var/lib/oir-flow/tls

COPY infra/deploy/platform/nginx.conf /etc/nginx/nginx.conf
COPY infra/deploy/platform/nginx-server.conf /etc/nginx/conf.d/default.conf
COPY infra/deploy/platform/php.ini /usr/local/etc/php/conf.d/zz-platform.ini
COPY infra/deploy/platform/php-fpm-www.conf /usr/local/etc/php-fpm.d/zzz-platform.conf
COPY infra/deploy/platform/start-web.sh /usr/local/bin/start-web

RUN cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
 && chmod 755 /usr/local/bin/start-web

WORKDIR /var/www/html

COPY --from=composer --chown=app:app /var/www/html /var/www/html
COPY --from=assets --chown=app:app /var/www/html/public/build /var/www/html/public/build

RUN mkdir -p \
      storage/app/private \
      storage/app/public \
      storage/app/livewire-tmp \
      storage/framework/cache/data \
      storage/framework/sessions \
      storage/framework/views \
      storage/framework/testing \
      storage/logs \
      storage/tenants \
      bootstrap/cache \
 && chown -R app:app storage bootstrap/cache \
 && chmod -R ug+rwx storage bootstrap/cache

USER app

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr

EXPOSE 8443

# Official docker-php-entrypoint exec's the command. Compose `queue` replaces CMD.
CMD ["/usr/local/bin/start-web"]
