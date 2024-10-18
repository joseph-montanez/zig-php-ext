const std = @import("std");

const allocator = std.heap.page_allocator;

const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const args = @import("args.zig");
const compile = @import("compile.zig");
const string = @import("string.zig");
const types = @import("types.zig");

pub const ParseState = struct {
    _flags: c_int,
    _min_num_args: u32,
    _max_num_args: u32,
    _num_args: u32,
    _i: u32,
    _real_arg: ?*php.zval,
    _arg: ?*php.zval,
    _expected_type: php.zend_expected_type,
    _error: ?[*]u8,
    _dummy: bool,
    _optional: bool,
    _error_code: c_int,

    pub fn init(
        flags: c_int,
        min_num_args: u32,
        max_num_args: u32,
        execute_data: ?*php.zend_execute_data,
    ) ParseState {
        const exec_data = execute_data orelse return ParseState{
            ._flags = flags,
            ._min_num_args = min_num_args,
            ._max_num_args = max_num_args,
            ._num_args = 0, // No args because it's null
            ._i = 0,
            ._real_arg = null,
            ._arg = null,
            ._expected_type = php.Z_EXPECTED_LONG,
            ._error = null,
            ._dummy = false,
            ._optional = false,
            ._error_code = php.ZPP_ERROR_OK,
        };

        return ParseState{
            ._flags = flags,
            ._min_num_args = min_num_args,
            ._max_num_args = max_num_args,
            ._num_args = args.EX_NUM_ARGS(exec_data),
            ._i = 0,
            ._real_arg = compile.ZEND_CALL_ARG(exec_data, 0),
            ._arg = null,
            ._expected_type = php.Z_EXPECTED_LONG,
            ._error = null,
            ._dummy = false,
            ._optional = false,
            ._error_code = php.ZPP_ERROR_OK,
        };
    }
};

fn EX(execute_data: ?*php.zend_execute_data, element: [*c]u8) *php.zval {
    if (execute_data) |e| {
        return @field(e.*, element);
    }
    return null;
}

fn ZEND_THIS(execute_data: ?*php.zend_execute_data) *php.zval {
    return EX(execute_data, "This");
}

fn getThis(execute_data: ?*php.zend_execute_data) ?*php.zval {
    const zthis = ZEND_THIS(execute_data);
    if (zthis != null and zthis.Z_TYPE_P == php.IS_OBJECT) {
        return zthis;
    }
    return null;
}

pub fn Z_PARAM_OPTIONAL(state: *ParseState) void {
    state._optional = true;
}

pub fn Z_PARAM_STRING(
    state: *ParseState,
    dest: *[*c]u8,
    dest_len: *usize,
) !void {
    if (!Z_PARAM_STRING_EX(state, dest, dest_len, false, false)) {
        return error.WrongArg;
    }
}

pub fn Z_PARAM_STRING_EX(
    state: *ParseState,
    dest: *[*c]u8,
    dest_len: *usize,
    check_null: bool,
    deref: bool,
) bool {
    Z_PARAM_PROLOGUE(state, deref, false);

    if (!php.zend_parse_arg_string(state._arg, dest, dest_len, check_null, state._i)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_STRING_OR_NULL else php.Z_EXPECTED_STRING;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return false;
    }

    return true;
}

pub fn Z_PARAM_PROLOGUE(
    state: *ParseState,
    deref: bool,
    separate: bool,
) void {
    state._i += 1;
    std.debug.assert(state._i <= state._min_num_args or state._optional == true);
    std.debug.assert(state._i > state._min_num_args or state._optional == false);

    if (state._optional and state._i > state._num_args) {
        return;
    }

    if (state._real_arg) |real_arg| {
        // const recast_real_arg: usize = @ptrFromInt(*php.zval);
        state._real_arg = @ptrFromInt(@intFromPtr(real_arg) + @sizeOf(php.zval));
        state._arg = state._real_arg;
    } else {
        state._arg = null;
    }

    if (deref and php.Z_ISREF_P(state._arg.?)) {
        state._arg = php.Z_REFVAL_P(state._arg.?);
    }

    if (separate) {
        types.SEPARATE_ZVAL_NOREF(state._arg.?);
    }
}

pub fn ZEND_PARSE_PARAMETERS_END(state: *ParseState) !void {
    std.debug.assert(state._i == state._max_num_args or state._max_num_args == std.math.maxInt(u32));

    if (state._error_code != php.ZPP_ERROR_OK) {
        if (!(state._flags & php.ZEND_PARSE_PARAMS_QUIET != 0)) {
            php.zend_wrong_parameter_error(state._error_code, state._i, state._error, state._expected_type, state._arg);
        }
        return error.ParameterParseFailure;
    }
}

pub fn ZEND_PARSE_PARAMETERS_START_EX(
    flags: c_int,
    min_num_args: u32,
    max_num_args: u32,
    execute_data: ?*php.zend_execute_data,
) ParseState {
    return ParseState.init(flags, min_num_args, max_num_args, execute_data);
}

pub fn ZEND_PARSE_PARAMETERS_START(min_num_args: u32, max_num_args: u32, execute_data: ?*php.zend_execute_data) ParseState {
    return ZEND_PARSE_PARAMETERS_START_EX(0, min_num_args, max_num_args, execute_data);
}

pub fn RETVAL_BOOL(return_value: *php.zval, b: bool) void {
    types.ZVAL_BOOL(return_value, b);
}

pub fn RETVAL_NULL(return_value: *php.zval) void {
    types.ZVAL_NULL(return_value);
}

pub fn RETVAL_LONG(return_value: *php.zval, l: i64) void {
    types.ZVAL_LONG(return_value, l);
}

pub fn RETVAL_DOUBLE(return_value: *php.zval, d: f64) void {
    types.ZVAL_DOUBLE(return_value, d);
}

pub fn RETVAL_STR(return_value: *php.zval, s: *php.zend_string) void {
    types.ZVAL_STR(return_value, s);
}

pub fn RETVAL_INTERNED_STR(return_value: *php.zval, s: *php.zend_string) void {
    types.ZVAL_INTERNED_STR(return_value, s);
}

pub fn RETVAL_NEW_STR(return_value: *php.zval, s: *php.zend_string) void {
    types.ZVAL_NEW_STR(return_value, s);
}

pub fn RETVAL_STR_COPY(return_value: *php.zval, s: *php.zend_string) void {
    types.ZVAL_STR_COPY(return_value, s);
}

pub fn RETVAL_STRING(return_value: *php.zval, s: [*c]const u8) void {
    types.ZVAL_STRING(return_value, s);
}

pub fn RETVAL_STRINGL(return_value: *php.zval, s: [*c]const u8, l: usize) void {
    types.ZVAL_STRINGL(return_value, s, l);
}

pub fn RETVAL_STRING_FAST(return_value: *php.zval, s: [*c]const u8) void {
    types.ZVAL_STRING_FAST(return_value, s);
}

pub fn RETVAL_STRINGL_FAST(return_value: *php.zval, s: [*c]const u8, l: usize) void {
    types.ZVAL_STRINGL_FAST(return_value, s, l);
}
pub fn ZVAL_EMPTY_STRING(z: *php.zval) void {
    types.ZVAL_INTERNED_STR(z, php.ZSTR_EMPTY_ALLOC());
}

pub fn RETVAL_EMPTY_STRING(return_value: *php.zval) void {
    ZVAL_EMPTY_STRING(return_value);
}

pub fn RETVAL_CHAR(return_value: *php.zval, c: u8) void {
    types.ZVAL_CHAR(return_value, c);
}

pub fn RETVAL_RES(return_value: *php.zval, r: *php.zend_resource) void {
    types.ZVAL_RES(return_value, r);
}

pub fn RETVAL_ARR(return_value: *php.zval, r: *php.zend_array) void {
    types.ZVAL_ARR(return_value, r);
}

pub fn RETVAL_EMPTY_ARRAY(return_value: *php.zval) void {
    types.ZVAL_EMPTY_ARRAY(return_value);
}

pub fn RETVAL_OBJ(return_value: *php.zval, r: *php.zend_object) void {
    types.ZVAL_OBJ(return_value, r);
}

pub fn RETVAL_OBJ_COPY(return_value: *php.zval, r: *php.zend_object) void {
    types.ZVAL_OBJ_COPY(return_value, r);
}

pub fn RETVAL_COPY(return_value: *php.zval, zv: *php.zval) void {
    types.ZVAL_COPY(return_value, zv);
}

pub fn RETVAL_COPY_VALUE(return_value: *php.zval, zv: *php.zval) void {
    types.ZVAL_COPY_VALUE(return_value, zv);
}

pub fn RETVAL_COPY_DEREF(return_value: *php.zval, zv: *php.zval) void {
    types.ZVAL_COPY_DEREF(return_value, zv);
}

pub fn RETVAL_ZVAL(return_value: *php.zval, zv: *php.zval, copy: bool, dtor: bool) void {
    types.ZVAL_ZVAL(return_value, zv, copy, dtor);
}

pub fn RETVAL_FALSE(return_value: *php.zval) void {
    types.ZVAL_FALSE(return_value);
}

pub fn RETVAL_TRUE(return_value: *php.zval) void {
    types.ZVAL_TRUE(return_value);
}

pub fn RETURN_BOOL(return_value: *php.zval, b: bool) void {
    RETVAL_BOOL(return_value, b);
    return;
}

pub fn RETURN_NULL(return_value: *php.zval) void {
    RETVAL_NULL(return_value);
    return;
}

pub fn RETURN_LONG(return_value: *php.zval, l: i64) void {
    RETVAL_LONG(return_value, l);
    return;
}

pub fn RETURN_DOUBLE(return_value: *php.zval, d: f64) void {
    RETVAL_DOUBLE(return_value, d);
    return;
}

pub fn RETURN_STR(return_value: *php.zval, s: *php.zend_string) void {
    RETVAL_STR(return_value, s);
    return;
}

pub fn RETURN_INTERNED_STR(return_value: *php.zval, s: *php.zend_string) void {
    RETVAL_INTERNED_STR(return_value, s);
    return;
}

pub fn RETURN_NEW_STR(return_value: *php.zval, s: *php.zend_string) void {
    RETVAL_NEW_STR(return_value, s);
    return;
}

pub fn RETURN_STR_COPY(return_value: *php.zval, s: *php.zend_string) void {
    RETVAL_STR_COPY(return_value, s);
    return;
}

pub fn RETURN_STRING(return_value: *php.zval, s: [*c]const u8) void {
    RETVAL_STRING(return_value, s);
}

pub fn RETURN_STRINGL(return_value: *php.zval, s: [*c]const u8, l: usize) void {
    RETVAL_STRINGL(return_value, s, l);
}

pub fn RETURN_STRING_FAST(return_value: *php.zval, s: [*c]const u8) void {
    RETVAL_STRING_FAST(return_value, s);
}

pub fn RETURN_STRINGL_FAST(s: [*c]const u8, l: usize, return_value: *php.zval) void {
    RETVAL_STRINGL_FAST(s, l, return_value);
}

pub fn RETURN_EMPTY_STRING(return_value: *php.zval) void {
    RETVAL_EMPTY_STRING(return_value);
    return;
}

pub fn RETURN_CHAR(return_value: *php.zval, c: u8) void {
    RETVAL_CHAR(return_value, c);
}

pub fn RETURN_RES(return_value: *php.zval, r: *php.zend_resource) void {
    RETVAL_RES(return_value, r);
}

pub fn RETURN_ARR(return_value: *php.zval, r: *php.zend_array) void {
    RETVAL_ARR(return_value, r);
}

pub fn RETURN_EMPTY_ARRAY(return_value: *php.zval) void {
    RETVAL_EMPTY_ARRAY(return_value);
}

pub fn RETURN_OBJ(return_value: *php.zval, r: *php.zend_object) void {
    RETVAL_OBJ(return_value, r);
}

pub fn RETURN_OBJ_COPY(return_value: *php.zval, r: *php.zend_object) void {
    RETVAL_OBJ_COPY(return_value, r);
}

pub fn RETURN_COPY(return_value: *php.zval, zv: *php.zval) void {
    RETVAL_COPY(return_value, zv);
}

pub fn RETURN_COPY_VALUE(return_value: *php.zval, zv: *php.zval) void {
    RETVAL_COPY_VALUE(return_value, zv);
    return;
}

pub fn RETURN_COPY_DEREF(zv: *php.zval, return_value: *php.zval) void {
    RETVAL_COPY_DEREF(zv, return_value);
    return;
}

pub fn RETURN_ZVAL(zv: *php.zval, copy: bool, dtor: bool, return_value: *php.zval) void {
    RETVAL_ZVAL(zv, copy, dtor, return_value);
    return;
}

pub fn RETURN_FALSE(return_value: *php.zval) void {
    RETVAL_FALSE(return_value);
    return;
}

pub fn RETURN_TRUE(return_value: *php.zval) void {
    RETVAL_TRUE(return_value);
    return;
}

pub fn RETURN_THROWS(return_value: *php.zval) void {
    _ = return_value;
    std.debug.assert(php.EG.exception != null);
}

pub fn ZEND_FENTRY(
    zend_name: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    num_args: u32,
    flags: u32,
) php.zend_function_entry {
    return php.zend_function_entry{
        .fname = zend_name,
        .handler = handler,
        .arg_info = arg_info,
        .num_args = num_args,
        .flags = flags,
    };
}

pub fn ZEND_FE(
    name: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    num_args: u32,
) php.zend_function_entry {
    return ZEND_FENTRY(name, handler, arg_info, num_args, 0);
}

pub fn ZEND_FE_END() php.zend_function_entry {
    return php.zend_function_entry{
        .fname = null,
        .handler = null,
        .arg_info = null,
        .num_args = 0,
        .flags = 0,
    };
}

pub fn PHP_FE_END() php.zend_function_entry {
    return ZEND_FE_END();
}

pub fn ZEND_FN(handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void) fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void {
    return handler;
}

pub fn ZEND_MN(handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void) fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void {
    return handler;
}

pub fn ZEND_NAMED_FUNCTION(handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void) void {
    handler(null, null);
}

pub fn ZEND_FUNCTION(handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void) void {
    ZEND_NAMED_FUNCTION(handler);
}

pub fn ZEND_METHOD(name: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void) void {
    ZEND_NAMED_FUNCTION(name);
}

pub fn ZEND_RAW_FENTRY(
    zend_name: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    num_args: u32,
    flags: u32,
) php.zend_function_entry {
    return ZEND_FENTRY(zend_name, handler, arg_info, num_args, flags);
}

pub fn ZEND_RAW_NAMED_FE(
    zend_name: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(zend_name, handler, arg_info, 0);
}

pub fn ZEND_NAMED_FE(
    zend_name: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
) php.zend_function_entry {
    return ZEND_RAW_NAMED_FE(zend_name, handler, arg_info);
}

pub fn ZEND_DEP_FE(
    name: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(name, handler, arg_info, php.ZEND_ACC_DEPRECATED);
}

pub fn ZEND_FALIAS(
    alias: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(alias, handler, arg_info, 0);
}

pub fn ZEND_DEP_FALIAS(
    alias: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(alias, handler, arg_info, php.ZEND_ACC_DEPRECATED);
}

pub fn ZEND_NAMED_ME(
    zend_name: [*c]const u8,
    name: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_FENTRY(zend_name, name, arg_info, flags);
}

pub fn ZEND_ME(
    classname: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    num_args: u32,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(classname, handler, arg_info, num_args, flags);
}

pub fn PHP_ME(
    classname: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    num_args: u32,
    flags: u32,
) php.zend_function_entry {
    return ZEND_ME(classname, handler, arg_info, num_args, flags);
}

pub fn ZEND_DEP_ME(
    classname: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(classname, handler, arg_info, flags | php.ZEND_ACC_DEPRECATED);
}

pub fn ZEND_ABSTRACT_ME(
    classname: [*c]const u8,
    arg_info: ?[*]php.zend_internal_arg_info,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(classname, null, arg_info, php.ZEND_ACC_PUBLIC | php.ZEND_ACC_ABSTRACT);
}

pub fn ZEND_ABSTRACT_ME_WITH_FLAGS(
    classname: [*c]const u8,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(classname, null, arg_info, flags);
}

pub fn ZEND_MALIAS(
    alias: [*c]const u8,
    handler: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(alias, handler, arg_info, flags);
}

pub fn ZEND_ME_MAPPING(
    name: [*c]const u8,
    func_name: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(name, func_name, arg_info, flags);
}

pub fn ZEND_NS_FENTRY(
    ns: [*c]const u8,
    zend_name: [*c]const u8,
    name: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(ns ++ "::" ++ zend_name, name, arg_info, flags);
}

pub fn ZEND_NS_RAW_FENTRY(
    ns: [*c]const u8,
    zend_name: [*c]const u8,
    name: fn (execute_data: ?*php.zend_execute_data, return_value: ?*php.zval) callconv(.C) void,
    arg_info: ?[*]php.zend_internal_arg_info,
    flags: u32,
) php.zend_function_entry {
    return ZEND_RAW_FENTRY(ns ++ "::" ++ zend_name, name, arg_info, flags);
}

pub fn Z_PARAM_GET_PREV_ZVAL(state: *ParseState, dest: *?php.zval) void {
    _ = php.zend_parse_arg_zval_deref(state._arg, &dest, 0);
}

pub fn Z_PARAM_ARRAY_EX2(state: *ParseState, dest: *php.zval, check_null: bool, deref: bool, separate: bool) !void {
    Z_PARAM_PROLOGUE(state, deref, separate);
    if (!php.zend_parse_arg_array(state._arg, &dest, check_null, 0)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_ARRAY_OR_NULL else php.Z_EXPECTED_ARRAY;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_ARRAY_EX(state: *ParseState, dest: *php.zval, check_null: bool, separate: bool) !void {
    return Z_PARAM_ARRAY_EX2(state, dest, check_null, separate, separate);
}

pub fn Z_PARAM_ARRAY(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_ARRAY_EX(state, dest, false, false);
}

pub fn Z_PARAM_ARRAY_OR_NULL(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_ARRAY_EX(state, dest, true, false);
}

pub fn Z_PARAM_ARRAY_OR_OBJECT_EX2(state: *ParseState, dest: *php.zval, check_null: bool, deref: bool, separate: bool) !void {
    Z_PARAM_PROLOGUE(state, deref, separate);
    if (!php.zend_parse_arg_array(state._arg, &dest, check_null, 1)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_ARRAY_OR_NULL else php.Z_EXPECTED_ARRAY;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_ARRAY_OR_OBJECT_EX(state: *ParseState, dest: *php.zval, check_null: bool, separate: bool) !void {
    return Z_PARAM_ARRAY_OR_OBJECT_EX2(state, dest, check_null, separate, separate);
}

pub fn Z_PARAM_ARRAY_OR_OBJECT(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_ARRAY_OR_OBJECT_EX(state, dest, false, false);
}

pub fn Z_PARAM_ITERABLE_EX(state: *ParseState, dest: *php.zval, check_null: bool) !void {
    Z_PARAM_PROLOGUE(state, false, false);
    if (!php.zend_parse_arg_iterable(state._arg, &dest, check_null)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_ITERABLE_OR_NULL else php.Z_EXPECTED_ITERABLE;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_ITERABLE(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_ITERABLE_EX(state, dest, false);
}

pub fn Z_PARAM_ITERABLE_OR_NULL(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_ITERABLE_EX(state, dest, true);
}

pub fn Z_PARAM_DOUBLE(state: *ParseState, dest: *f64) !void {
    return Z_PARAM_DOUBLE_EX(state, dest, null, false, false);
}

pub fn Z_PARAM_DOUBLE_OR_NULL(state: *ParseState, dest: *f64, is_null: *bool) !void {
    return Z_PARAM_DOUBLE_EX(state, dest, is_null, true, false);
}

pub fn Z_PARAM_OBJECT_EX(state: *ParseState, dest: *php.zval, check_null: bool, deref: bool) !void {
    Z_PARAM_PROLOGUE(state, deref, false);
    if (!php.zend_parse_arg_object(state._arg, &dest, null, check_null)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_OBJECT_OR_NULL else php.Z_EXPECTED_OBJECT;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_OBJECT(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_OBJECT_EX(state, dest, false, false);
}

pub fn Z_PARAM_OBJECT_OR_NULL(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_OBJECT_EX(state, dest, true, false);
}

pub fn Z_PARAM_RESOURCE_EX(state: *ParseState, dest: *php.zval, check_null: bool, deref: bool) !void {
    Z_PARAM_PROLOGUE(state, deref, false);
    if (!php.zend_parse_arg_resource(state._arg, &dest, check_null)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_RESOURCE_OR_NULL else php.Z_EXPECTED_RESOURCE;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_RESOURCE(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_RESOURCE_EX(state, dest, false, false);
}

pub fn Z_PARAM_RESOURCE_OR_NULL(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_RESOURCE_EX(state, dest, true, false);
}

pub fn Z_PARAM_PATH_EX(state: *ParseState, dest: *[*c]u8, dest_len: *usize, check_null: bool, deref: bool) !void {
    Z_PARAM_PROLOGUE(state, deref, false);
    if (!php.zend_parse_arg_path(state._arg, &dest, &dest_len, check_null, state._i)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_PATH_OR_NULL else php.Z_EXPECTED_PATH;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_PATH(state: *ParseState, dest: *[*c]u8, dest_len: *usize) !void {
    return Z_PARAM_PATH_EX(state, dest, dest_len, false, false);
}

pub fn Z_PARAM_PATH_OR_NULL(state: *ParseState, dest: *[*c]u8, dest_len: *usize) !void {
    return Z_PARAM_PATH_EX(state, dest, dest_len, true, false);
}
pub fn Z_PARAM_OBJ_OR_CLASS_NAME_EX(state: *ParseState, dest: *php.zval, allow_null: bool) !void {
    Z_PARAM_PROLOGUE(state, false, false);
    if (!php.zend_parse_arg_obj_or_class_name(state._arg, &dest, allow_null)) {
        state._expected_type = if (allow_null) php.Z_EXPECTED_OBJECT_OR_CLASS_NAME_OR_NULL else php.Z_EXPECTED_OBJECT_OR_CLASS_NAME;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn Z_PARAM_OBJ_OR_CLASS_NAME(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_OBJ_OR_CLASS_NAME_EX(state, dest, false);
}

pub fn Z_PARAM_OBJ_OR_CLASS_NAME_OR_NULL(state: *ParseState, dest: *php.zval) !void {
    return Z_PARAM_OBJ_OR_CLASS_NAME_EX(state, dest, true);
}

pub fn Z_PARAM_DOUBLE_EX(state: *ParseState, dest: *f64, is_null: *bool, check_null: bool, deref: bool) !void {
    Z_PARAM_PROLOGUE(state, deref, false);
    if (!php.zend_parse_arg_double(state._arg, @as([*c]f64, @ptrCast(dest)), is_null, check_null, state._i)) {
        state._expected_type = if (check_null) php.Z_EXPECTED_DOUBLE_OR_NULL else php.Z_EXPECTED_DOUBLE;
        state._error_code = php.ZPP_ERROR_WRONG_ARG;
        return error.WrongArg;
    }
}

pub fn ZEND_NS_NAME(ns: []const u8, name: []const u8) []u8 {
    var result = allocator.alloc(u8, ns.len + 1 + name.len) catch {
        return "";
    };
    @memcpy(result[0..ns.len], ns);
    result[ns.len] = '\\';
    @memcpy(result[ns.len + 1 ..], name);
    return result;
}

pub fn INIT_CLASS_ENTRY_EX(class_container: *php.zend_class_entry, class_name: []const u8, class_name_len: usize, functions: ?*php.zend_function_entry) void {
    @memset(std.mem.asBytes(class_container), 0);
    if (php.zend_string_init_interned) |init_interned| {
        class_container.name = init_interned(class_name.ptr, class_name_len, true);
    } else {
        @panic("zend_string_init_interned is not available");
    }
    class_container.default_object_handlers = &php.std_object_handlers;
    class_container.info.internal.builtin_functions = functions;
}

pub fn INIT_CLASS_ENTRY_INIT_METHODS(class_container: *php.zend_class_entry, functions: ?*php.zend_function_entry) void {
    class_container.default_object_handlers = &std.object_handlers;
    class_container.constructor = null;
    class_container.destructor = null;
    class_container.clone = null;
    class_container.serialize = null;
    class_container.unserialize = null;
    class_container.create_object = null;
    class_container.get_static_method = null;
    class_container.__call = null;
    class_container.__callstatic = null;
    class_container.__tostring = null;
    class_container.__get = null;
    class_container.__set = null;
    class_container.__unset = null;
    class_container.__isset = null;
    class_container.__debugInfo = null;
    class_container.__serialize = null;
    class_container.__unserialize = null;
    class_container.parent = null;
    class_container.num_interfaces = 0;
    class_container.trait_names = null;
    class_container.num_traits = 0;
    class_container.trait_aliases = null;
    class_container.trait_precedences = null;
    class_container.interfaces = null;
    class_container.get_iterator = null;
    class_container.iterator_funcs_ptr = null;
    class_container.arrayaccess_funcs_ptr = null;
    class_container.info.internal.module = null;
    class_container.info.internal.builtin_functions = functions;
}

pub fn INIT_CLASS_ENTRY(class_container: *php.zend_class_entry, class_name: []const u8, functions: ?*php.zend_function_entry) void {
    INIT_CLASS_ENTRY_EX(class_container, class_name, class_name.len, functions);
}

pub fn INIT_NS_CLASS_ENTRY(class_container: *php.zend_class_entry, ns: []const u8, class_name: []const u8, functions: ?*php.zend_function_entry) void {
    const full_class_name = ZEND_NS_NAME(ns, class_name);
    defer allocator.free(full_class_name);
    INIT_CLASS_ENTRY(class_container, full_class_name, functions);
}
