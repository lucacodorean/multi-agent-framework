<?php

/**
 * Prove the seam tests ACTUALLY RAN. Not that the suite passed — that they executed.
 *
 * Every case in the `live-engine` group SKIPS unless `ENGINE_LIVE_SMOKE=1`, so dropping that
 * variable leaves the gate green, "OK", exit 0, HAVING EXERCISED THE SEAM ZERO TIMES. So
 * `--log-junit`, a documented machine-readable surface unlike the rendered summary, is
 * asserted instead: the group matched tests at all, none skipped, none failed or errored.
 *
 * Usage:  php assert-seam-executed.php <junit.xml>
 */
declare(strict_types=1);

/**
 * Seam cases expected to execute today, across the two files carrying the `live-engine` group.
 *
 * NOT the number of `->group('live-engine')` calls in the tree — that reads 10 for a group of
 * 12, because a dataset case counts once per row. The quantity to match is the selected-case
 * count this file prints, which is where both bounds below take their reading.
 *
 * A BAND, not a floor: `executed < this` means coverage shrank, `selected > this` means the
 * constant has fallen behind the group. Both bounds are checked below, and the failure
 * messages there carry what to do about each.
 *
 * ANEXA 3 LIVE CASE — asserts a 200 against the interim mock layout, not 501. When a national
 * specimen replaces `engine.app.anexa3_mock`, REWRITE the case (keep the count), never delete it.
 */
const EXPECTED_SEAM_TESTS = 12;

function fail(string $message): never
{
    fwrite(STDERR, PHP_EOL.'seam execution check FAILED: '.$message.PHP_EOL);
    exit(1);
}

$reportPath = $argv[1] ?? null;

if ($reportPath === null) {
    fail('usage: assert-seam-executed.php <junit.xml>');
}

if (! is_file($reportPath) || filesize($reportPath) === 0) {
    fail(
        "no JUnit report at {$reportPath}.".PHP_EOL
        .'The test run produced no machine-readable result, so the number of executed seam'.PHP_EOL
        .'cases cannot be established — and an unverifiable count is exactly what this'.PHP_EOL
        .'check exists to refuse. Treat it as zero.'
    );
}

$report = simplexml_load_file($reportPath);

if ($report === false) {
    fail("the JUnit report at {$reportPath} could not be parsed as XML.");
}

// Counted from the leaf <testcase> elements rather than the <testsuites> summary attributes:
// the attributes are version-dependent and have been absent or aggregated differently across
// PHPUnit releases, whereas a testcase element per executed test is the stable part of the
// format. A skipped test still emits a <testcase>, carrying a <skipped/> child — which is
// precisely the distinction this check turns on.
$cases = $report->xpath('//testcase') ?: [];
// The CASE elements that carry a <skipped/> child, not the <skipped/> children themselves.
// Measured reason: PHPUnit records no skip message here at all — `markTestSkipped`'s text
// does not reach the report — so a listing built from the <skipped/> elements can only print
// "(no reason recorded)" and names nothing. The `name` attribute lives one level up, on the
// testcase, and it is the only identifying thing the report actually carries.
$skippedCases = $report->xpath('//testcase[skipped]') ?: [];
$skipped = $report->xpath('//testcase/skipped') ?: [];
$failures = $report->xpath('//testcase/failure') ?: [];
$errors = $report->xpath('//testcase/error') ?: [];

$total = count($cases);
$skippedCount = count($skipped);
$executed = $total - $skippedCount;

echo sprintf(
    'seam cases: %d executed, %d skipped, %d failed, %d errored (of %d selected)%s',
    $executed,
    $skippedCount,
    count($failures),
    count($errors),
    $total,
    PHP_EOL,
);

if ($total === 0) {
    fail(
        'the --group=live-engine selection matched NO tests at all.'.PHP_EOL
        .'Either the group name changed, or the seam tests were moved or deleted. The gate'.PHP_EOL
        .'would otherwise report success having verified nothing.'
    );
}

if ($skippedCount > 0) {
    // NAME THE CASES, and name BOTH gating variables rather than only the famous one: an
    // earlier version asserted "these skip unless ENGINE_LIVE_SMOKE=1" and, measured, went red
    // pointing at a variable that was set the whole time. Describe, do not diagnose.
    $names = array_map(
        static function (SimpleXMLElement $case): string {
            $name = trim((string) ($case['name'] ?? '')) ?: '(unnamed case)';
            // The reason lives in the `message` ATTRIBUTE in some PHPUnit versions and as
            // element text in others; the version in use here emits a bare <skipped/> with
            // neither, which is why the case name above carries the diagnosis.
            $skip = $case->skipped[0] ?? null;
            $reason = $skip === null
                ? ''
                : (trim((string) ($skip['message'] ?? '')) ?: trim((string) $skip));

            return '  - '.$name.($reason !== '' ? ': '.$reason : '');
        },
        $skippedCases,
    );

    fail(
        sprintf('%d of %d seam case(s) SKIPPED. The seam was not fully exercised.', $skippedCount, $total).PHP_EOL
        .'Skipped:'.PHP_EOL
        .implode(PHP_EOL, $names).PHP_EOL
        .PHP_EOL
        .'Seam cases skip when the environment they need is absent FROM THE TEST PROCESS.'.PHP_EOL
        .'Two variables gate them today, both supplied by infra/ci/seam-suite.sh:'.PHP_EOL
        .'  ENGINE_LIVE_SMOKE=1        — gates every case in both files'.PHP_EOL
        .'  ENGINE_UNCONFIGURED_URL    — gates only the 503 case, which needs the second,'.PHP_EOL
        .'                               deliberately unconfigured engine container'.PHP_EOL
        .'Check that the gate still passes them to the runner and that no name has drifted.'
    );
}

if ($executed < EXPECTED_SEAM_TESTS) {
    fail(sprintf(
        'only %d seam case(s) executed, expected %d.'.PHP_EOL
        .'Seam coverage shrank. If a case was deliberately removed, lower EXPECTED_SEAM_TESTS'.PHP_EOL
        .'in this file in the same commit, so the reduction is reviewed rather than absorbed.'.PHP_EOL
        .PHP_EOL
        .'IF YOU ARE HERE HAVING JUST DELETED A LIVE SEAM CASE (inspectExport / Anexa mock /'.PHP_EOL
        .'etc.) because it went red: read the note above this constant first. Prefer rewriting'.PHP_EOL
        .'the case against the served operation over lowering EXPECTED_SEAM_TESTS.',
        $executed,
        EXPECTED_SEAM_TESTS,
    ));
}

if (count($failures) > 0 || count($errors) > 0) {
    fail('the seam group reported failures or errors — see the test output above.');
}

// THE UPPER BOUND — checked LAST, deliberately: a real failure and a stale constant can both be
// true of one run, and reporting "the number is out of date" would bury the broken case under
// bookkeeping. Compared against SELECTED, not executed — `$total` is what the constant claims
// to know, and stays honest if a future check ever permits a skip.
if ($total > EXPECTED_SEAM_TESTS) {
    fail(sprintf(
        'the live-engine group now selects %d case(s), but EXPECTED_SEAM_TESTS says %d.'.PHP_EOL
        .'Nothing is broken — seam coverage GREW, and this constant did not.'.PHP_EOL
        .PHP_EOL
        .'Raise EXPECTED_SEAM_TESTS to %d in this file, in the same commit that adds the case.'.PHP_EOL
        .PHP_EOL
        .'WHY THIS IS RED RATHER THAN A FRIENDLY NOTICE, since being blocked by a passing test'.PHP_EOL
        .'suite is annoying and the reason is not obvious: a number that is merely "at least"'.PHP_EOL
        .'stops detecting a DELETED case the moment the group outgrows it, and it does so'.PHP_EOL
        .'silently. That is not hypothetical — this constant sat at 6 against a group of 7,'.PHP_EOL
        .'and during that window a case could have been removed with this gate still green.'.PHP_EOL
        .'A notice would have been printed into the log of a passing build, where it was'.PHP_EOL
        .'already being ignored. See the reasoning above the constant.'.PHP_EOL
        .PHP_EOL
        .'If tests/ is not yours to change and this file is not either, raising the number is'.PHP_EOL
        .'a lightweight task to platform-engineer — the same arrangement as WARNING_BASELINE'.PHP_EOL
        .'in infra/ci/contract-lint.sh.',
        $total,
        EXPECTED_SEAM_TESTS,
        $total,
    ));
}

echo 'seam execution check: '.$executed.' case(s) really ran against a live engine.'.PHP_EOL;
