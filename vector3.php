<?php

var_dump(test1());
var_dump(test2("Zig"));
var_dump(text_reverse(test2("Zig")));


$v = new raylib\Vector3(1.0, 2.0, 3);

echo var_dump($v), PHP_EOL;

$v->x = 2.0;


// This works, because you are grabbing a temp copy and mutating the parent object
$v->x = $v->x + 1;

// This does not work, because you are taking a temp copy and mutating it directly
// Developer needs to add this feature in their PHP Class (not easy)
$v->x++; // Will not increment

echo 'x:', $v->x, PHP_EOL;