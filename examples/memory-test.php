<?php

// Keep errors out of the HTTP response; log them instead.
ini_set('display_errors', '0');
ini_set('log_errors', '1');

header('Content-Type: text/plain; charset=utf-8');

$headers = function_exists('getallheaders') ? getallheaders() : [];
$token = '51dc63aedf5cc8447e75a4e4a7a1b0257af6b6ef910cf13cfc62b0226521005f';

if (
    !isset($headers['X-Lab-Token']) ||
    !hash_equals($token, $headers['X-Lab-Token'])
) {
    http_response_code(404);
    exit("Not found\n");
}

// Set a deliberately low limit for this test request only.
if (ini_set('memory_limit', '32M') === false) {
    http_response_code(500);
    exit("RESULT: CONFIGURATION_ERROR\n");
}

// Buffer output so a fatal error cannot leave a partial success response.
ob_start();

// Reserve memory that the shutdown handler can release after exhaustion.
$reserve = str_repeat('R', 1024 * 1024);

register_shutdown_function(function () use (&$reserve) {
    $error = error_get_last();

    $memoryExhausted = $error !== null
        && $error['type'] === E_ERROR
        && strpos($error['message'], 'Allowed memory size') !== false;

    if ($memoryExhausted) {
        // Free reserved memory to help the handler finish.
        $reserve = null;

        while (ob_get_level() > 0) {
            ob_end_clean();
        }

        if (!headers_sent()) {
            http_response_code(500);
            header('Content-Type: text/plain; charset=utf-8');
        }

        echo "RESULT: MEMORY_LIMIT_REACHED\n";
        echo "PHP_VERSION: " . PHP_VERSION . "\n";
        echo "LIMIT: 32M\n";
    }
});

echo "Starting controlled memory-limit test\n";
echo "PHP_VERSION: " . PHP_VERSION . "\n";
echo "LIMIT: 32M\n";

$chunks = [];

for ($i = 1; $i <= 100; $i++) {
    $chunks[] = str_repeat('A', 1024 * 1024);
}

// Reaching this line means the allocation completed.
echo "RESULT: COMPLETED\n";

ob_end_flush();
