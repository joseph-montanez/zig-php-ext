# Zig PHP Extension

A super bearly bones example of getting starting with Zig to write PHP extensions (PECL).

## 1. Customizing PHP C Source

The source code currently for PHP does not work out of the box in Zig and needs a few changes. So you cannot use off the shelf installs and need custom builds of PHP. I've designed some scripts to compile `php-src` for you with the patched code. This will compile thread-safe and non-thread-safe versions of debug and release.

### Zig C-Translate Bugs

Right now there are several blockers for using `php-src` "as-is".

**Old C Style Array Access**

https://github.com/ziglang/zig/issues/21684 - Zig does not have enough information to allow this type of operation, causing an out of bounds check at runtime. Current work around is `wrapper.c` avoid using those functions translated by Zig.


**Dependency Loop Error**

https://github.com/ziglang/zig/issues/19392 - Zig if it runs across a typedef that also has a definition, and that definition in this example `execute_data` is declared later, it creates a loop error.

`execute_data` is in `INTERNAL_FUNCTION_PARAMETERS` and cannot resolved recursively since `zif_handler` forward declared (declared before execute_data struct that it depends on).


**Zig C-Translate Atomics Bug**

[Support _Atomic in translate-c #11415](https://github.com/ziglang/zig/issues/11415) - `PHP-SRC` uses atomics for booleans and this is something while Zig supports, the C-Translate does not.

```
~/.zig-cache/o/1b3858c1f114d7c470e34e6eba3d4113/cimport.zig:28545:19: error: opaque types have unknown size and therefore cannot be directly embedded in structs
    vm_interrupt: zend_atomic_bool = @import("std").mem.zeroes(zend_atomic_bool),
                  ^~~~~~~~~~~~~~~~
~/.zig-cache/o/1b3858c1f114d7c470e34e6eba3d4113/cimport.zig:28499:39: note: opaque declared here
pub const struct_zend_atomic_bool_s = opaque {};
                                      ^~~~~~~~~
```

For the time being when you run into this you need to go into the `cimport.zig` file then replace. I do try to auto patch this, but you first build will fail.

```zig
pub const struct_zend_atomic_bool_s = opaque {};
pub const zend_atomic_bool = struct_zend_atomic_bool_s;
```

With the following:

```zig
pub const struct_zend_atomic_bool_s = extern struct {
    value: @import("std").atomic.Value(bool),
};
pub const zend_atomic_bool = struct_zend_atomic_bool_s;
```

While I already provide patches for the C code, there is no work around for this at this time other than manual patching since the cimport.zig changes depeneding on flags and platforms. I also provide an auto-fix when you build but basically you have to twice each time you change your code. The other option is to disable atomic operations (disable C11 support), this is fine for the non-thread safe versions of PHP, but for ZTS (thread safe) its not advisable and the workaround above is the only known solution.

### Debian/Ubuntu

This will prompt a **password** to auto install packages to build and fetch `php-src`

    chmod +x Scripts/build_ubuntu.sh
    ./Scripts/build_ubuntu.sh

### macOS

This will use brew to install `Bison 3.x`, however you do need the **XCode toolchain** installed.

    chmod +x Scripts/build_macos.sh
    ./Scripts/build_macos.sh

### Windows

TODO...

## 2. Building Zig Extension

PHP has several modes, right now `zig build` uses ZTS/NON-ZTS/DEBUG/RELEASE for thread-safety/non-thread-safety. If you need a thread-safety version you can use:

    ./build.sh --zig /path/to/zig --zts --action clean  --action configure --action build --action run
    # Release ZTS version
    ./build.sh --zig /path/to/zig --zts --release --action clean  --action configure --action build --action run

If not, and okay with non-thread safety version:

    ./build.sh --zig /path/to/zig --action clean --action configure --action build --action run
    # Release NTS version
    ./build.sh --zig /path/to/zig  --release --clean --action configure --action build --action run

`build.zig` is a work in progress and does not function right now.


If you get an error `error: opaque types have unknown size and therefore cannot be directly embedded in structs` just build a second time without clean/configure:

    ./build.sh --zig /path/to/zig --action clean --action configure --action build --action run
    ./build.sh --zig /path/to/zig --action build --action run

## PHP Extension Files For Development

The following are a list of files you will want to start with. This will help you get starts with writing your own extension in Zig.

`ext.zig` - The root Zig code to register your PHP functions and class written in Zig.

`vector3.zig` - Example of how to write a PHP class in Zig.

`php-zig.patch` - Custom C patches to `php-src` to help Zig's C-Translate system.

`wrapper.c/h` - Work arounds for C-Translate issues that cannot be patched out.

`zend.zig` - C Macro's Translation, warning its a work in progress.


## Performance

I've not bothered to optimized any code so this is just an out of the box experience.

### PHP 8.3.12 Release NTS

1,000,000,000 (One Billion) iterations of a string reverse

| Version           | Time (secs) (Linux x64) | Time (secs) (macOS aarch64) |   Memory Usage (MB) (macOS) | Time (%) (macOS) | Memory Usage (MB) (Linux)   | Time (%) (Linux) |
|:------------------|------------------------:|----------------------------:|----------------------------:|:-----------------|:----------------------------|:-----------------|
| C 03 Optimization |                 14.1434 |                     23.9626 |                         2.5 | 0%               | N/A                         | 18.35% slower    |
| C 02 Optimization |                 14.6329 |                     24.2401 |                         3.6 | 1% slower        | N/A                         | 22.45% slower    |
| Zig ReleaseFast   |                  12.363 |                     24.5845 |                         2.9 | 2% slower        | N/A                         | 3.46% slower     |
| PHP’s strrev      |                   11.95 |                     26.6163 |                         3.5 | 11% slower       | N/A                         | 0% slower        |
| Zig ReleaseSafe   |                 15.7793 |                      29.835 |                         4   | 24% slower       | N/A                         | 32.04% slower    |
| Pure PHP          |                 145.905 |                     280.365 |                         3.8 | 1070% slower     | N/A                         | 1120.96% slower  |


### Differences from C API

PHP internals uses macros to create a DSL for writing PHP extensions. I've started the process to make this easier but they do not work 100% the same because
of how the macros are designed in the C API. This makes working in Zig more verbose, but at least you get type information and better type safety.

**String Reverse Zig Implementation**

```zig
pub fn zif_text_reverse(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) callconv(.C) void {
    var var_str: [*c]u8 = null;
    var var_len: usize = 0;
    var retval: ?*php.zend_string = null;

    var paramState = zend.ZEND_PARSE_PARAMETERS_START(1, 1, execute_data);
    zend.Z_PARAM_STRING(&paramState, &var_str, &var_len) catch |err| {
        std.debug.print("`str` parameter error: {}\n", .{err});
        return;
    };
    zend.ZEND_PARSE_PARAMETERS_END(&paramState) catch |err| {
        std.debug.print("end parameter error: {}\n", .{err});
        return;
    };

    // Handle empty string case
    if (var_len == 0) {
        zend.RETURN_EMPTY_STRING(return_value);
        return;
    }

    // Allocate memory for the zend string
    retval = php.zend_string_alloc(var_len, false);
    if (retval) |nonNullRetval| {
        const str_val_ptr: [*]u8 = @as([*]u8, @ptrCast(zend.ZSTR_VAL(nonNullRetval)));
        var i: usize = 0;
        while (i < var_len) : (i += 1) {
            str_val_ptr[i] = var_str[var_len - i - 1];
        }
        // Null-terminate the string
        str_val_ptr[var_len] = 0;

        zend.RETURN_STR(return_value, nonNullRetval);
    } else {
        std.debug.print("Failed to allocate memory for zend_string\n", .{});
        zend.RETURN_EMPTY_STRING(return_value);
    }
}
```

**String Reverse C Implementation**

```c
PHP_FUNCTION(ctext_reverse)
{
	char *var = "";
	size_t var_len = 0;
	zend_string *retval;

	ZEND_PARSE_PARAMETERS_START(1, 1)
		Z_PARAM_STRING(var, var_len)
	ZEND_PARSE_PARAMETERS_END();

	// Create a reversed version of the input string
	retval = zend_string_alloc(var_len, 0);
	for (size_t i = 0; i < var_len; i++) {
		ZSTR_VAL(retval)[i] = var[var_len - i - 1];
	}
	ZSTR_VAL(retval)[var_len] = '\0'; // Null-terminate the string

	RETURN_STR(retval);
}
```
