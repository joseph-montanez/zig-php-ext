<?php

function print_timing($start_time, $label)
{
    $end_time = microtime(true);
    $duration = $end_time - $start_time;
    echo $label . ": " . $duration . " seconds\n";
}

function strrev2($string)
{
    $reversed = "";
    $length = strlen($string);

    for ($i = $length - 1; $i >= 0; $i--) {
        $reversed .= $string[$i];
    }

    return $reversed;
}

$t = microtime(true);
for ($i = 0; $i < 1000000000; $i++) {
    $c = strrev2("Hello World");
}
print_timing($t, "PHP strrev Function Time");
