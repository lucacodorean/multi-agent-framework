<?php

/**
 * Guard the assumption that lets the platform CI job get away with running NO queue worker.
 *
 * CI has no supervisord and no long-lived container, so a job runs only if the pipeline drains
 * the queue itself — but phpunit.xml pins QUEUE_CONNECTION to `sync`, so dispatched work runs
 * inline and a `queue:work` step would drain an always-empty queue. The premise is asserted
 * rather than trusted because it is one edit away from false: name a real driver and every
 * assertion about a dispatched effect silently passes on an empty queue. Read straight from
 * phpunit.xml, not from a booted application, which would introduce the layering this verifies.
 */
declare(strict_types=1);

const CONFIG_PATH = 'phpunit.xml';
const VARIABLE = 'QUEUE_CONNECTION';

/** The only driver that runs dispatched work with no separate worker process. */
const INLINE_DRIVER = 'sync';

function fail(string $message): never
{
    fwrite(STDERR, PHP_EOL.'queue guard FAILED: '.$message.PHP_EOL);
    exit(1);
}

if (! is_file(CONFIG_PATH)) {
    fail(CONFIG_PATH.' not found — run this from the repository root.');
}

$config = simplexml_load_file(CONFIG_PATH);

if ($config === false) {
    fail(CONFIG_PATH.' could not be parsed as XML.');
}

$declared = null;

foreach ($config->php->env as $entry) {
    if ((string) $entry['name'] === VARIABLE) {
        $declared = (string) $entry['value'];
    }
}

if ($declared === null) {
    fail(
        VARIABLE.' is no longer declared in '.CONFIG_PATH.'.'.PHP_EOL
        .'The suite would then inherit whatever the environment supplies, which in CI is nothing —'.PHP_EOL
        .'so the effective driver becomes unpredictable. Declare it explicitly, or, if a real queue'.PHP_EOL
        .'is now intended, drain it in run-suite.sh with `artisan queue:work --stop-when-empty`.'
    );
}

if ($declared !== INLINE_DRIVER) {
    fail(
        VARIABLE.' is "'.$declared.'", not "'.INLINE_DRIVER.'".'.PHP_EOL
        .'This pipeline runs NO queue worker, because with `sync` there is nothing to drain.'.PHP_EOL
        .'With a real driver, dispatched work never runs and every test asserting on its EFFECT'.PHP_EOL
        .'passes on an empty queue instead of failing.'.PHP_EOL
        .'Either restore `sync` in '.CONFIG_PATH.', or add an explicit drain to'.PHP_EOL
        .'infra/ci/platform/run-suite.sh: `php artisan queue:work --stop-when-empty`.'
    );
}

echo 'queue guard: '.VARIABLE.'='.$declared.' — dispatched work runs inline, no worker needed.'.PHP_EOL;
