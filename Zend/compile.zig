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

pub fn ZEND_CALL_VAR_NUM(call: *php.zend_execute_data, n: c_int) *php.zval {
    const n_cast: usize = @intCast(n);
    return @ptrFromInt(@intFromPtr(call) + ZEND_CALL_FRAME_SLOT() * @sizeOf(php.zval) + n_cast * @sizeOf(php.zval));
}

pub fn ZEND_CALL_ARG(call: *php.zend_execute_data, n: c_int) *php.zval {
    return ZEND_CALL_VAR_NUM(call, n - 1);
}
