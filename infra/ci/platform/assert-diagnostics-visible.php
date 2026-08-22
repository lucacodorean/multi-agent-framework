<?php

/**
 * Prove the interpreter's own diagnostics can REACH the gate before the gate claims none exist.
 *
 * Run by infra/ci/platform/run-suite.sh immediately before the suite: the downstream scan for
 * `PHP Warning:` / `Fatal error:` lines produces a CLEAN RESULT when it is blind, and a clean
 * result is indistinguishable from success. Measured, the condition is not the obvious
 * `display_errors` one — diagnostics reach the captured stream when EITHER display_errors is on
 * (stdout) OR log_errors is on AND error_log is unset (stderr, which `artisan test` forwards
 * onto stdout). `error_log` is inspected rather than just the two booleans because logging to a
 * file leaves every "is logging on?" check passing while nobody reads the output.
 */
declare(strict_types=1);

/**
 * PHP boolean ini values arrive as strings and not always as "1" — `display_errors` reports
 * "STDOUT" in this image. So "enabled" is defined by exclusion: anything that is not one of
 * the documented off-values counts as on. Inverting this (listing the on-values) would read
 * "STDOUT" as off, which is the exact misreading that produced the wrong guard.
 */
function iniEnabled(string $directive): bool
{
    $value = strtolower(trim((string) ini_get($directive)));

    return ! in_array($value, ['', '0', 'off', 'false', 'no', 'none'], true);
}

$displayErrors = iniEnabled('display_errors');
$logErrors = iniEnabled('log_errors');
$errorLog = trim((string) ini_get('error_log'));

// Only when error_log is EMPTY does log_errors reach stderr; with a destination set, the
// diagnostics go there instead and never enter the stream the gate captures.
$logReachesStderr = $logErrors && $errorLog === '';

if ($displayErrors || $logReachesStderr) {
    $channel = $displayErrors ? 'display_errors → stdout' : 'log_errors → stderr';
    echo 'diagnostic channel: '.$channel.' (compile-time PHP diagnostics will reach the gate)'.PHP_EOL;

    exit(0);
}

fwrite(STDERR, PHP_EOL.'diagnostic visibility check FAILED: PHP diagnostics cannot reach this gate.'.PHP_EOL);
fwrite(STDERR, sprintf(
    '  display_errors = %s'.PHP_EOL.'  log_errors     = %s'.PHP_EOL.'  error_log      = %s'.PHP_EOL,
    var_export(ini_get('display_errors'), true),
    var_export(ini_get('log_errors'), true),
    $errorLog === '' ? '<unset — would reach stderr>' : var_export($errorLog, true),
));
fwrite(STDERR, PHP_EOL
    .'With neither channel open, warnings raised while LOADING a test file are discarded'.PHP_EOL
    .'silently. The scan that follows the suite would then find nothing and report a clean'.PHP_EOL
    .'tree — not because the tree is clean, but because nothing was listening.'.PHP_EOL
    .PHP_EOL
    .'That is the failure this gate exists to refuse, arriving inside the gate itself'.PHP_EOL
    .'(docs/conventions/orchestration.md rule 4). A check that cannot fail is worse than no check,'.PHP_EOL
    .'because it is reported as a pass.'.PHP_EOL
    .PHP_EOL
    .'Fix by restoring EITHER channel: display_errors=1, or log_errors=1 with error_log'.PHP_EOL
    .'unset so diagnostics go to stderr. Do not "fix" it by deleting the scan.'.PHP_EOL);

exit(1);
