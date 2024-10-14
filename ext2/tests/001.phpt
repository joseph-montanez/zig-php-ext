--TEST--
Check if ext2 is loaded
--EXTENSIONS--
ext2
--FILE--
<?php
echo 'The extension "ext2" is available';
?>
--EXPECT--
The extension "ext2" is available
