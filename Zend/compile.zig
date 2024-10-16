const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const types = @import("types.zig");
const args = @import("args.zig");

usingnamespace types;
usingnamespace args;

pub fn ZEND_CALL_FRAME_SLOT() usize {
    return (@sizeOf(php.zend_execute_data) + @sizeOf(php.zval) - 1) / @sizeOf(php.zval);
}

pub fn ZEND_CALL_VAR(call: *php.zend_execute_data, n: c_int) *php.zval {
    const n_cast: usize = @intCast(n);
    return @ptrFromInt(@intFromPtr(call) + n_cast * @sizeOf(php.zval));
}

pub fn ZEND_CALL_VAR_NUM(call: *php.zend_execute_data, n: isize) *php.zval {
    const zval_ptr: [*]php.zval = @ptrCast(@alignCast(call));
    const offset: isize = @as(isize, @intCast(ZEND_CALL_FRAME_SLOT())) + n;
    return &zval_ptr[@intCast(@as(usize, @max(0, offset)))];
}

pub fn ZEND_CALL_ARG(call: *php.zend_execute_data, n: isize) *php.zval {
    return ZEND_CALL_VAR_NUM(call, n - 1);
}
