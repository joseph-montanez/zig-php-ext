const std = @import("std");
const allocator = std.heap.page_allocator;

const config = @cImport({
    @cInclude("php_config.h");
    @cInclude("config.h");
});

const php = @cImport({
    @cDefine("_GNU_SOURCE", "1");
    @cDefine("ZEND_DEBUG", "1");
    @cDefine("ZTS", "1");
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const zend = @import("zend.zig");

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

var arginfo_test1: [1]php.zend_internal_arg_info = [_]php.zend_internal_arg_info{zend.ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(false, 0, php.IS_VOID, false, false)};
fn zif_test1(execute_data: [*c]php.zend_execute_data, _: [*c]php.zval) callconv(.C) void {
    if (execute_data.*.This.u2.num_args != 0) {
        php.zend_wrong_parameters_none_error();
        return;
    }
    std.debug.print("test1() - The extension {s} is loaded and working!\r\n", .{"EXT"});
}

var arginfo_test2: [2]php.zend_internal_arg_info = [_]php.zend_internal_arg_info{ zend.ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(false, 0, php.IS_STRING, false, false), zend.ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(false, "str", php.IS_STRING, false, "\"\"") };
fn zif_test2(execute_data: [*c]php.zend_execute_data, return_value: [*c]php.zval) callconv(.C) void {
    var buffer: [6]u8 = [_]u8{ 'W', 'o', 'r', 'l', 'd', 0 };
    var var_str: [*c]u8 = &buffer[0];
    var var_len: usize = 5;
    var retval: ?*php.zend_string = null;

    const _flags: c_int = 0;
    const _min_num_args: u32 = 0;
    const _max_num_args: u32 = 1;
    const _num_args: u32 = execute_data.*.This.u2.num_args;
    var _i: u32 = 0;
    var _real_arg: ?*php.zval = null;
    var _arg: ?*php.zval = null;
    var _expected_type: php.zend_expected_type = php.Z_EXPECTED_LONG;
    const _error: ?[*]u8 = null;
    // var _dummy: bool = false;
    var _optional: bool = false;
    var _error_code: c_int = 0;

    if (_num_args < _min_num_args or _num_args > _max_num_args) {
        if ((_flags & (1 << 1)) != 0) {
            php.zend_wrong_parameters_count_error(_min_num_args, _max_num_args);
        }
        _error_code = 1;
        return;
    }

    const zval_ptr_from_execute_data: *php.zval = @ptrCast(execute_data); // ((zval *)(execute_data))
    const execute_data_size: usize = @sizeOf(php.zend_execute_data); // sizeof(zend_execute_data)
    const zval_size = @sizeOf(php.zval);
    const offset: usize = (execute_data_size + zval_size - 1) / zval_size; // sizeof(zend_execute_data) + sizeof(zval) - 1
    const tmp_offset: isize = @intCast(offset); // cast to int like ((int)(sizeof(zend_execute_data) + sizeof(zval) - 1))
    const adjusted_offset: usize = tmp_offset + 0 - 1; // ((int)(((int)(0)) - 1))
    const tmp_zval_ptr_from_execute_data: usize = @intFromPtr(zval_ptr_from_execute_data);
    _real_arg = @ptrFromInt(tmp_zval_ptr_from_execute_data + adjusted_offset * zval_size);

    // Optional flag and index increment (as per the original code)
    _optional = true;
    _i += 1;

    std.debug.assert(_i <= _min_num_args or _optional == true);
    std.debug.assert(_i > _min_num_args or _optional == false);

    if (_optional) {
        if (_i > _num_args) return;
    }

    if (_real_arg) |real_arg| {
        const real_arg_as_int: usize = @intFromPtr(real_arg);
        const next_real_arg_as_int: usize = real_arg_as_int + @sizeOf(php.zval);
        _real_arg = @ptrFromInt(next_real_arg_as_int);
    }
    _arg = _real_arg;

    if (false) {
        if (php.zval_get_type(_arg) == 10) {
            _arg = &_arg.value.ref.val;
        }
    }

    if (false) {
        var _zv: *php.zval = _arg;
        std.debug.assert(php.zval_get_type(_zv) != 10);

        if (php.zval_get_type(_zv) == 7) {
            var _arr: *php.zend_array = _zv.value.arr;
            if (php.zend_gc_refcount(&_arr.gc) > 1) {
                const __arr: *php.zend_array = php.zend_array_dup(_arr);
                _zv.value.arr = __arr;
                _zv.u1.type_info = 7 | ((1 << 0) << 8) | ((1 << 1) << 8);
                php.zend_gc_try_delref(&_arr.gc);
            }
        }
    }

    if (!php.zend_parse_arg_string(_arg, &var_str, &var_len, false, _i)) {
        _expected_type = if (false) php.Z_EXPECTED_STRING_OR_NULL else php.Z_EXPECTED_STRING;
        _error_code = php.ZPP_ERROR_WRONG_ARG;
        return;
    }

    std.debug.assert(_i == _max_num_args or _max_num_args == std.math.maxInt(u32));

    if (_error_code != 0) {
        if ((_flags & (1 << 1)) != 0) {
            php.zend_wrong_parameter_error(_error_code, _i, _error, _expected_type, _arg);
        }
        return;
    }

    // Format the string in Zig
    const var_str_slice: []const u8 = @as([*]const u8, var_str)[0..var_len];
    const formatted_str = format_string(var_str_slice) catch {
        std.debug.print("NO! GOD NO!\n", .{});
        return;
    };

    retval = php.zend_string_init_wrapper(formatted_str.ptr, formatted_str.len, 0);

    if (retval) |nonOptionalRetval| {
        // std.debug.print("NO! GOD NO?\n", .{});
        zend.RETURN_STR(nonOptionalRetval, @constCast(return_value));
    } else {
        std.debug.print("NO! GOD NO NO!\n", .{});
        // Handle the case where retval is null
        return;
    }
}

const ext_functions = [_]php.zend_function_entry{
    zend.ZEND_FE("test1", zif_test1, &arginfo_test1, arginfo_test1.len - 1),
    zend.ZEND_FE("test2", zif_test2, &arginfo_test2, arginfo_test2.len - 1),
    zend.ZEND_FE_END(),
};

export fn zm_info_ext(_: [*c]php.zend_module_entry) callconv(.C) void {
    // Implement this function if needed
}

export fn zm_startup_ext(activation_type: c_int, module_number: c_int) callconv(.C) php.zend_result {
    std.debug.print("Raylib module startup. Type: {d}, Module number: {d}\n", .{ activation_type, module_number });
    return php.SUCCESS;
}

export fn zm_shutdown_ext(activation_type: c_int, module_number: c_int) callconv(.C) php.zend_result {
    std.debug.print("Raylib module shutdown. Type: {d}, Module number: {d}\n", .{ activation_type, module_number });
    return php.SUCCESS;
}

export fn zm_activate_ext(activation_type: c_int, module_number: c_int) callconv(.C) php.zend_result {
    std.debug.print("Raylib module activated. Type: {d}, Module number: {d}\n", .{ activation_type, module_number });
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
        .zend_debug = 0,
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
        .globals_id_ptr = null,
        .globals_ctor = null,
        .globals_dtor = null,
        .post_deactivate_func = null,
        .module_started = 0,
        .type = 0,
        .handle = null,
        .module_number = 0,
        .build_id = std.fmt.comptimePrint("API{d},{s},{s}", .{
            php.PHP_API_VERSION,
            if (@hasDecl(config, "ZTS")) "TS" else "NTS",
            if (@hasDecl(config, "ZEND_DEBUG")) "debug" else "release",
        }),
    };

    break :blk BaseModuleEntry{
        .entry = entry,
        .globals_id_or_ptr = if (@hasDecl(config, "ZTS")) null else 0,
    };
};

var ext_module_entry: BaseModuleEntry = base_module_entry;

fn get_module() callconv(.C) [*c]php.zend_module_entry {
    std.debug.print("get_module called!\n", .{});
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
        @export(&get_module, .{ .name = "get_module", .linkage = .strong });
    } else {
        const ext_log = "(Runtime) EXT not compiled as module";
        _ = ext_log;
    }
}
