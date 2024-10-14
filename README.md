# Zig PHP Extension

A super bearly bones example of getting starting with Zig to write PHP extensions (PECL).

## 1. Customizing PHP C Source

The source code current for PHP does not work out of the box in Zig and needs a few changes. So you cannot use off the shelf installs and need a custom build of PHP. I've designed some scripts to compile `php-src` for you with the patched code. This will compile a thread-safe and non-thread-safe version.

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

PHP has several modes, right now `zig build` only uses ZTS/NON-ZTS for thread-safety. If you need a thread-safety version you can use:

    ./build.sh --zig /path/to/zig --zts --action configure --action build --action run

If not, and okay with non-thread safety version:

    ./build.sh --zig /path/to/zig --action configure --action build --action run


## Performance

I've not bothered to optimized any code so this is just an out of the box experience.

### PHP 8.3.12 Release NTS macOS aarch64 - M1 Mac Mini

1,000,000,000 (One Billion) iterations of a string reverse

| Version               | Time (seconds)         | Memory Usage |
|-----------------------|------------------------|--------------|
| C 03 Optimization     | 23.962615966797 seconds| 2.5MB        |
| C 02 Optimization     | 24.240067005157 seconds| 3.6MB        |
| Zig ReleaseFast       | 24.58452296257 seconds | 2.9MB        |
| PHP's `strrev`        | 26.616330862045 seconds| 3.5MB        |
| Zig ReleaseSafe       | 29.834988117218 seconds| 4.0MB        |
| Pure PHP              | 280.36521196365 seconds| 3.8MB        |

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
