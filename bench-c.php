<?php

function print_timing($start_time, $label)
{
    $end_time = microtime(true);
    $duration = $end_time - $start_time;
    echo $label . ": " . $duration . " seconds\n";
}

$t = microtime(true);
for ($i = 0; $i < 1000000000; $i++) {
    $c = ctext_reverse("Hello World");
}
print_timing($t, "C Function Time");
