#!/usr/bin/env bash
# Web process: php-fpm + nginx (TLS on :8443). Not a migrate/bootstrap entrypoint (T6).
set -euo pipefail

mkdir -p /tmp/nginx/{client_body,proxy,fastcgi,uwsgi,scgi} /tmp/oir-flow-tls

# Prefer operator-mounted certs (Let's Encrypt names). Otherwise a self-signed
# pair so the container can listen on 8443 without a host proxy. Non-root cannot
# write a named volume created as root, so generated files stay in /tmp.
tls_cert="${TLS_CERT:-/var/lib/oir-flow/tls/fullchain.pem}"
tls_key="${TLS_KEY:-/var/lib/oir-flow/tls/privkey.pem}"
runtime_cert=/tmp/oir-flow-tls/fullchain.pem
runtime_key=/tmp/oir-flow-tls/privkey.pem

if [[ -s "${tls_cert}" && -s "${tls_key}" ]]; then
    ln -sfn "${tls_cert}" "${runtime_cert}"
    ln -sfn "${tls_key}" "${runtime_key}"
else
    host="${TLS_HOSTNAME:-localhost}"
    if [[ "${host}" =~ ^[0-9.]+$ ]]; then
        san="IP:${host},IP:127.0.0.1,DNS:localhost"
    else
        san="DNS:${host},DNS:localhost,IP:127.0.0.1"
    fi
    openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
        -keyout "${runtime_key}" \
        -out "${runtime_cert}" \
        -subj "/CN=${host}" \
        -addext "subjectAltName=${san}"
    chmod 600 "${runtime_key}"
fi

# Central schema must exist before nginx accepts /console (console_users).
# Retry: compose starts web in parallel with db; pg_isready on db is not
# visible from this script. tenants:* is a no-op when the registry is empty.
attempt=0
until php artisan migrate --force --no-interaction; do
    attempt=$((attempt + 1))
    if [[ "${attempt}" -ge 15 ]]; then
        echo "error: central migrate did not succeed after ${attempt} attempts" >&2
        exit 1
    fi
    sleep 2
done
php artisan tenants:migrate --force --no-interaction
php artisan tenants:seed --force --no-interaction

php-fpm --nodaemonize --force-stderr &
fpm_pid=$!

nginx -g 'daemon off;' &
nginx_pid=$!

shutdown() {
    kill -QUIT "${nginx_pid}" "${fpm_pid}" 2>/dev/null || true
}
trap shutdown TERM INT

wait -n "${nginx_pid}" "${fpm_pid}" || true
shutdown
wait || true
