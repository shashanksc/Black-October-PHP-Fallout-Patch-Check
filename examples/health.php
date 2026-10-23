<?php
header('Content-Type: text/plain; charset=utf-8');

http_response_code(200);

echo "STATUS: OK\n";
echo "PHP_VERSION: " . PHP_VERSION . "\n";
echo "PHP_SAPI: " . PHP_SAPI . "\n";
echo "MEMORY_LIMIT: " . ini_get('memory_limit') . "\n";
