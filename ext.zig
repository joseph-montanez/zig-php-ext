const std = @import("std");
const allocator = std.heap.page_allocator;

const config = @cImport({
    @cInclude("php_config.h");
    @cInclude("config.h");
});

const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const zend = @import("zend.zig");
const vector3 = @import("vector3.zig");

usingnamespace zend;

// const PhpAllocator = struct {
//     pub fn alloc(_: *PhpAllocator, len: usize) !*u8 {
//         const filename = "ext.zig"; // Set this to the current filename
//         const lineno: u32 = 25; // Set this to the current line number

//         const ptr = php._emalloc(len, filename, lineno, filename, lineno);
//         if (ptr == null) {
//             return error.OutOfMemory;
//         }
//         return @ptrCast(ptr);
//     }

//     pub fn free(_: *PhpAllocator, ptr: *u8) void {
//         const filename = "ext.zig"; // Set this to the current filename
//         const lineno: u32 = 36; // Set this to the current line number

//         php._efree(ptr, filename, lineno, filename, lineno);
//     }
// };

fn format_string(name: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "Hello {s}", .{name});
}

var arginfo_test1: [1]php.zend_internal_arg_info = [_]php.zend_internal_arg_info{zend.ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(0, false, php.IS_VOID, false, false)};
fn zif_test1(execute_data: [*c]php.zend_execute_data, _: [*c]php.zval) callconv(.C) void {
    if (execute_data.*.This.u2.num_args != 0) {
        php.zend_wrong_parameters_none_error();
        return;
    }
    std.debug.print("test1() - The extension {s} is loaded and working!\r\n", .{"EXT"});
}

var arginfo_test2: [2]php.zend_internal_arg_info = [_]php.zend_internal_arg_info{ zend.ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(0, false, php.IS_STRING, false, false), zend.ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(false, "str", php.IS_STRING, false, "\"\"") };
fn zif_test2(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) callconv(.C) void {
    var buffer: [6]u8 = [_]u8{ 'W', 'o', 'r', 'l', 'd', 0 };
    var var_str: [*c]u8 = &buffer[0];
    var var_len: usize = 5;
    var retval: ?*php.zend_string = null;

    var paramState = zend.ZEND_PARSE_PARAMETERS_START(0, 1, execute_data);
    zend.Z_PARAM_OPTIONAL(&paramState);
    zend.Z_PARAM_STRING(&paramState, &var_str, &var_len) catch {};
    zend.ZEND_PARSE_PARAMETERS_END(&paramState) catch {};

    var formatted_str: [100]u8 = undefined;
    const result = std.fmt.bufPrint(&formatted_str, "Hello {s}", .{var_str}) catch {
        return;
    };

    retval = php.zend_string_init_wrapper(result.ptr, result.len, 0);

    if (retval) |nonOptionalRetval| {
        std.debug.print("String copied. Attempting to return...\n", .{});

        // Try to return the string
        zend.RETURN_STR(return_value, nonOptionalRetval);

        std.debug.print("RETURN_STR completed\n", .{});
    } else {
        std.debug.print("How did we get here?!\n", .{});
        // Handle the case where retval is null
        return;
    }
}

var arginfo_text_reverse: [2]php.zend_internal_arg_info = [_]php.zend_internal_arg_info{ zend.ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(1, false, php.IS_STRING, false, false), zend.ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(false, "str", php.IS_STRING, false, "\"\"") };
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

const ext_functions = [_]php.zend_function_entry{
    zend.ZEND_FE("test1", zif_test1, &arginfo_test1, arginfo_test1.len - 1),
    zend.ZEND_FE("test2", zif_test2, &arginfo_test2, arginfo_test2.len - 1),
    zend.ZEND_FE("text_reverse", zif_text_reverse, &arginfo_text_reverse, arginfo_text_reverse.len - 1),
    zend.ZEND_FE_END(),
};

export fn zm_info_ext(_: [*c]php.zend_module_entry) callconv(.C) void {
    // Implement this function if needed
}

export fn zm_startup_ext(module_type: c_int, module_number: c_int) callconv(.C) php.zend_result {
    vector3.php_raylib_vector3_startup(module_type, module_number);

    return php.SUCCESS;
}

export fn zm_shutdown_ext(_: c_int, _: c_int) callconv(.C) php.zend_result {
    return php.SUCCESS;
}

export fn zm_activate_ext(_: c_int, _: c_int) callconv(.C) php.zend_result {
    return php.SUCCESS;
}

const BaseModuleEntry = struct {
    entry: php.zend_module_entry,
    globals_id_or_ptr: if (@hasDecl(config, "ZTS")) ?*c_uint else c_uint,
};

const base_module_entry = blk: {
    const entry = php.zend_module_entry{
        .size = @sizeOf(php.zend_module_entry),
        .zend_api = php.PHP_API_VERSION,
        .zend_debug = if (isDebugBuild()) 0 else 1,
        .zts = if (@hasDecl(config, "ZTS")) 1 else 0,
        .ini_entry = null,
        .name = "ext",
        .functions = &ext_functions,
        .module_startup_func = zm_startup_ext,
        .module_shutdown_func = zm_shutdown_ext,
        .request_startup_func = zm_activate_ext,
        .request_shutdown_func = null,
        .info_func = zm_info_ext,
        .version = "1.0",
        .globals_size = 0,
        .globals_ctor = null,
        .globals_dtor = null,
        .post_deactivate_func = null,
        .module_started = 0,
        .type = 0,
        .handle = null,
        .module_number = 0,
        .build_id = std.fmt.comptimePrint("API{d},{s}{s}", .{
            php.PHP_API_VERSION,
            if (@hasDecl(config, "ZTS")) "TS" else "NTS",
            if (isDebugBuild()) ",debug" else "",
        }),
    };

    break :blk BaseModuleEntry{
        .entry = entry,
        .globals_id_or_ptr = if (@hasDecl(config, "ZTS")) null else 0,
    };
};

fn isDebugBuild() bool {
    if (@hasDecl(config, "ZEND_DEBUG")) {
        const debug_value = @field(config, "ZEND_DEBUG");
        return debug_value != 0;
    }
    return false;
}

var ext_module_entry: BaseModuleEntry = base_module_entry;

fn get_module() callconv(.C) [*c]php.zend_module_entry {
    // std.debug.print("get_module called!\n", .{});
    return &ext_module_entry.entry;
}

comptime {
    if (@hasDecl(config, "COMPILE_DL_EXT")) {
        if (@hasDecl(config, "ZTS")) {
            // Prepare a runtime log
            const zts_log = "(Runtime) ZTS is defined";
            _ = zts_log; // Prevent unused variable warning
            // This is equivalent to ZEND_TSRMLS_CACHE_DEFINE() in C
            @export(php.ZEND_TSRMLS_CACHE, .{ .name = "ZEND_TSRMLS_CACHE", .linkage = .strong });
        }

        const ext_log = "(Runtime) EXT compiled as module";
        _ = ext_log;
        @export(get_module, .{ .name = "get_module", .linkage = .strong });
    } else {
        const ext_log = "(Runtime) EXT not compiled as module";
        _ = ext_log;
    }
}
