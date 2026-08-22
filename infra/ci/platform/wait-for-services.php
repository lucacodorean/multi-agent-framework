<?php

/**
 * Block until PostgreSQL and Redis are actually answering, or fail with which one did not.
 *
 * Protocols, not `sleep`: a container that is "up" is not a database accepting connections, and
 * PostgreSQL in particular listens briefly then restarts during init. PHP rather than
 * pg_isready/redis-cli, because those belong to the SERVER images while PDO is the client the
 * suite will use. The credentials mirror phpunit.xml's <php> block, duplicated rather than
 * parsed: this file must report "the database is unreachable" without depending on it.
 */
declare(strict_types=1);

const TIMEOUT_SECONDS = 90;
const INTERVAL_SECONDS = 2;

/** Connected to `postgres`, not to the test database: the suite creates the latter itself. */
const POSTGRES_DSN = 'pgsql:host=db;port=5432;dbname=postgres';
const POSTGRES_USER = 'db';
const POSTGRES_PASSWORD = 'db';

const REDIS_HOST = 'redis';
const REDIS_PORT = 6379;

/**
 * Poll one service until its probe returns true.
 *
 * @param  callable(): bool  $probe  returns true when ready; may throw, which counts as not ready
 */
function awaitService(string $label, callable $probe): void
{
    $deadline = time() + TIMEOUT_SECONDS;
    $lastError = 'no attempt completed';

    while (time() < $deadline) {
        try {
            if ($probe() === true) {
                echo "  ok   {$label}".PHP_EOL;

                return;
            }
            $lastError = 'probe returned false';
        } catch (Throwable $error) {
            $lastError = $error->getMessage();
        }

        sleep(INTERVAL_SECONDS);
    }

    fwrite(STDERR, PHP_EOL."error: {$label} was not ready within ".TIMEOUT_SECONDS.'s.'.PHP_EOL);
    fwrite(STDERR, 'last error: '.$lastError.PHP_EOL);
    exit(1);
}

awaitService('postgres (db:5432)', static function (): bool {
    $pdo = new PDO(POSTGRES_DSN, POSTGRES_USER, POSTGRES_PASSWORD, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 3,
    ]);

    // A real round trip. Constructing the PDO alone can succeed against a cluster that is
    // still finishing initdb and about to restart.
    return $pdo->query('SELECT 1')->fetchColumn() !== false;
});

awaitService('redis (redis:6379)', static function (): bool {
    $socket = @fsockopen(REDIS_HOST, REDIS_PORT, $errorCode, $errorMessage, 3);

    if ($socket === false) {
        throw new RuntimeException($errorMessage !== '' ? $errorMessage : 'connection refused');
    }

    try {
        // PING over the real protocol, so a listening-but-not-serving Redis does not pass.
        fwrite($socket, "PING\r\n");
        $reply = fgets($socket);

        return is_string($reply) && str_starts_with($reply, '+PONG');
    } finally {
        fclose($socket);
    }
});

echo 'services ready.'.PHP_EOL;
