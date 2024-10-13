const std = @import("std");

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
    return php.zend_parse_arg_string(state._arg, dest, dest_len, check_null, state._i);
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

pub fn RETURN_STR(s: *php.zend_string, return_value: *php.zval) void {
    RETVAL_STR(s, return_value);
}

pub fn RETVAL_STR(s: *php.zend_string, return_value: *php.zval) void {
    ZVAL_STR(return_value, s);
}

pub fn ZVAL_STR(z: *php.zval, s: *php.zend_string) void {
    z.value.str = s;

    if (string.ZSTR_IS_INTERNED(s)) {
        z.u1.type_info = php.IS_INTERNED_STRING_EX;
    } else {
        z.u1.type_info = php.IS_STRING_EX;
    }
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
