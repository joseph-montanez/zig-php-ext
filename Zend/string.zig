const std = @import("std");

const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const types = @import("types.zig");

pub fn ZSTR_IS_INTERNED(s: *php.zend_string) bool {
    return (types.GC_FLAGS(s) & php.IS_STR_INTERNED) != 0;
}
