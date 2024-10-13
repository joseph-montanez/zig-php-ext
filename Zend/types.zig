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

pub fn ZEND_TYPE_INIT_NONE(type_mask: u32) php.zend_type {
    return php.zend_type{ .ptr = null, .type_mask = type_mask };
}

pub fn ZEND_TYPE_INIT_MASK(type_mask: u32) php.zend_type {
    return php.zend_type{ .ptr = null, .type_mask = type_mask };
}

pub fn ZEND_TYPE_INIT_PTR(ptr: ?*anyopaque, type_mask: u32) php.zend_type {
    return .{
        .ptr = ptr,
        .type_mask = type_mask,
    };
}

pub fn ZEND_TYPE_INIT_CODE(code: u32, allow_null: bool, extra_flags: u32) php.zend_type {
    var mask: u32 = 0;

    if (code == php._IS_BOOL) {
        mask = php.MAY_BE_BOOL;
    } else if (code == php.IS_ITERABLE) {
        mask = php._ZEND_TYPE_ITERABLE_BIT;
    } else if (code == php.IS_MIXED) {
        mask = php.MAY_BE_ANY;
    } else {
        mask = 1 << code;
    }

    if (allow_null) {
        mask |= php._ZEND_TYPE_NULLABLE_BIT;
    }

    return ZEND_TYPE_INIT_MASK(mask | extra_flags);
}

pub fn GC_TYPE_INFO(p: *php.zend_string) u32 {
    return p.gc.u.type_info;
}

pub fn GC_TYPE(p: *php.zend_string) u32 {
    return php.zval_gc_type(GC_TYPE_INFO(p));
}

pub fn GC_FLAGS(p: *php.zend_string) u32 {
    return php.zval_gc_flags(GC_TYPE_INFO(p));
}
