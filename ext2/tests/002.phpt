--TEST--
test1() Basic test
--EXTENSIONS--
ext2
--FILE--
<?php
$ret = test1();

var_dump($ret);
?>
--EXPECT--
The extension ext2 is loaded and working!
NULL
