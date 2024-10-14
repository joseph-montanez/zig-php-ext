<?php

function print_timing($start_time, $label)
{
    $end_time = microtime(true);
    $duration = $end_time - $start_time;
    echo $label . ": " . $duration . " seconds\n";
}

function print_memory_usage($start_memory, $label)
{
    $end_memory = memory_get_usage();
    $memory_diff = $end_memory - $start_memory;
    echo $label . ": " . $memory_diff . " bytes\n";
}

$start_memory = memory_get_usage();
$t = microtime(true);
for ($i = 0; $i < 1000000000; $i++) {
    $zig = text_reverse("Hello World"); // Assuming text_reverse is a valid function from Zig
}
print_timing($t, "Zig Function Time");
print_memory_usage($start_memory, "Memory Usage Difference");
