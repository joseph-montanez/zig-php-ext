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
usingnamespace types;

const compile = @import("compile.zig");
usingnamespace compile;

pub fn EX_NUM_ARGS(execute_data: ?*php.zend_execute_data) u32 {
    if (execute_data) |e| {
        return e.This.u2.num_args;
    }
    return 0;
}

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

pub fn ZEND_ARG_INFO(pass_by_ref: bool, name: [*c]const u8) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_NONE(ZEND_ARG_INFO_FLAGS(pass_by_ref, false, false)),
        .default_value = null,
    };
}

pub fn ZEND_ARG_INFO_WITH_DEFAULT_VALUE(pass_by_ref: bool, name: [*c]const u8, default_value: [*c]const u8) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_NONE(ZEND_ARG_INFO_FLAGS(pass_by_ref, false, false)),
        .default_value = default_value,
    };
}

pub fn ZEND_ARG_VARIADIC_INFO(pass_by_ref: bool, name: [*c]const u8) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_NONE(ZEND_ARG_INFO_FLAGS(pass_by_ref, true, false)),
        .default_value = null,
    };
}

pub fn ZEND_ARG_TYPE_INFO(pass_by_ref: bool, name: [*c]const u8, type_hint: u32, allow_null: bool) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_CODE(type_hint, allow_null, ZEND_ARG_INFO_FLAGS(pass_by_ref, false, false)),
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

pub fn ZEND_ARG_VARIADIC_TYPE_INFO(pass_by_ref: bool, name: [*c]const u8, type_hint: u32, allow_null: bool) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_CODE(type_hint, allow_null, ZEND_ARG_INFO_FLAGS(pass_by_ref, true, false)),
        .default_value = null,
    };
}

pub fn ZEND_ARG_TYPE_MASK(pass_by_ref: bool, name: [*c]const u8, type_mask: u32, default_value: [*c]const u8) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_MASK(type_mask | ZEND_ARG_INFO_FLAGS(pass_by_ref, false, false)),
        .default_value = default_value,
    };
}

pub fn ZEND_ARG_OBJ_TYPE_MASK(pass_by_ref: bool, name: [*c]const u8, class_name: [*c]const u8, type_mask: u32, default_value: [*c]const u8) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = name,
        .type = types.ZEND_TYPE_INIT_CLASS_CONST_MASK(class_name, type_mask | ZEND_ARG_INFO_FLAGS(pass_by_ref, false, false)),
        .default_value = default_value,
    };
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(required_num_args: usize, return_reference: bool, type_code: u32, allow_null: bool, is_tentative_return_type: bool) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = @as([*c]const u8, @ptrFromInt(required_num_args)), // Cast the integer to a pointer
        .type = types.ZEND_TYPE_INIT_CODE(type_code, allow_null, ZEND_ARG_INFO_FLAGS(return_reference, false, is_tentative_return_type)),
        .default_value = null,
    };
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX(name: [*c]const u8, return_reference: bool, required_num_args: usize, type_code: u32, allow_null: bool) php.zend_internal_arg_info {
    return ZEND_BEGIN_ARG_WITH_RETURN_TYPE_INFO_EX2(name, return_reference, required_num_args, type_code, allow_null, false);
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_TYPE_MASK_EX2(return_reference: bool, required_num_args: usize, type_code: u32, is_tentative_return_type: bool) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = @as([*c]const u8, @ptrFromInt(required_num_args)),
        .type = types.ZEND_TYPE_INIT_MASK(type_code | ZEND_ARG_INFO_FLAGS(return_reference, false, is_tentative_return_type)),
        .default_value = null,
    };
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_TYPE_MASK_EX(name: [*c]const u8, return_reference: bool, required_num_args: usize, type_code: u32) php.zend_internal_arg_info {
    return ZEND_BEGIN_ARG_WITH_RETURN_TYPE_MASK_EX2(name, return_reference, required_num_args, type_code, false);
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_OBJ_TYPE_MASK_EX2(return_reference: bool, required_num_args: usize, class_name: [*c]const u8, type_code: u32, is_tentative_return_type: bool) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = @as([*c]const u8, @ptrFromInt(required_num_args)),
        .type = types.ZEND_TYPE_INIT_CLASS_CONST_MASK(class_name, type_code | ZEND_ARG_INFO_FLAGS(return_reference, false, is_tentative_return_type)),
        .default_value = null,
    };
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_OBJ_TYPE_MASK_EX(name: [*c]const u8, return_reference: bool, required_num_args: usize, class_name: [*c]const u8, type_code: u32) php.zend_internal_arg_info {
    return ZEND_BEGIN_ARG_WITH_RETURN_OBJ_TYPE_MASK_EX2(name, return_reference, required_num_args, class_name, type_code, false);
}

pub fn ZEND_BEGIN_ARG_WITH_RETURN_OBJ_INFO_EX2(return_reference: bool, required_num_args: usize, class_name: [*c]const u8, allow_null: bool, is_tentative_return_type: bool) php.zend_internal_arg_info {
    return php.zend_internal_arg_info{
        .name = @as([*c]const u8, @ptrFromInt(required_num_args)),
        .type = types.ZEND_TYPE_INIT_CLASS_CONST(class_name, allow_null, ZEND_ARG_INFO_FLAGS(return_reference, false, is_tentative_return_type)),
        .default_value = null,
    };
}

pub fn ZEND_END_ARG_INFO() void {}
