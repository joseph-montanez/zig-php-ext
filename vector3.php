<?php

$v = new raylib\Vector3(1.0, 2.0, 3);

echo var_dump($v), PHP_EOL;

$v->x = 2.0;

// var_dump($v);

echo "Going to increment .x!\n";
$v->x = $v->x + 1;
echo "I completed a one plus itself, now trying += 1!\n";
$v->x++;
echo "Am i alive2?\n";

echo 'x:', $v->x, PHP_EOL;