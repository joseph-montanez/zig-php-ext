const php = @cImport({
    @cDefine("_GNU_SOURCE", "1");
    @cDefine("ZEND_DEBUG", "1");
    @cDefine("ZTS", "1");
    @cInclude("php_config.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const types = @import("types.zig");
usingnamespace types;

pub fn ZEND_ARG_INFO_FLAGS(pass_by_ref: bool, is_variadic: bool, is_tentative: bool) u32 {
    var flags: u32 = 0;

    if (pass_by_ref) {
        flags |= @as(u32, 1) << php.ZEND_SEND_MODE_SHIFT;
    }

    if (is_variadic) {
        flags |= php.ZEND_IS_VARIADIC_BIT;
    }

    if (is_tentative) {
        flags |= php.ZEND_IS_TENTATIVE_BIT;
    }

    return flags;
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(
    return_reference: bool,
    _: usize,
    type_code: u32,
    allow_null: bool,
    is_tentative_return_type: bool,
) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = null,
        .type = types.ZEND_TYPE_INIT_CODE(type_code, allow_null, ZEND_ARG_INFO_FLAGS(return_reference, false, is_tentative_return_type)),
        .default_value = null,
    };
}

pub fn ZEND_ARG_TYPE_INFO_WITH_DEFAULT_VALUE(pass_by_ref: bool, name: [*c]const u8, type_hint: u32, allow_null: bool, default_value: [*c]const u8) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_CODE(type_hint, allow_null, ZEND_ARG_INFO_FLAGS(pass_by_ref, false, false)),
        .default_value = default_value,
    };
}

pub fn EX_NUM_ARGS(execute_data: ?*php.zend_execute_data) u32 {
    if (execute_data) |e| {
        return e.This.u2.num_args;
    }
    return 0;
}
