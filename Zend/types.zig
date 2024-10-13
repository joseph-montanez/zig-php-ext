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

pub fn ZVAL_DEREF(z: *php.zval) void {
    if (php.Z_ISREF_P(z)) {
        z.* = php.Z_REFVAL_P(z);
    }
}

pub fn ZVAL_DEINDIRECT(z: *php.zval) void {
    if (php.Z_TYPE_P(z) == php.IS_INDIRECT) {
        z.* = php.Z_INDIRECT_P(z);
    }
}

pub fn ZVAL_OPT_DEREF(z: *php.zval) void {
    if (php.Z_OPT_ISREF_P(z)) {
        z.* = php.Z_REFVAL_P(z);
    }
}

pub fn ZVAL_MAKE_REF(zv: *php.zval) void {
    if (!php.Z_ISREF_P(zv)) {
        php.ZVAL_NEW_REF(zv, zv);
    }
}

pub fn ZVAL_UNREF(z: *php.zval) void {
    const ref = php.Z_REF_P(z);
    std.debug.assert(php.Z_ISREF_P(z));
    php.ZVAL_COPY_VALUE(z, &ref.val);
    php.efree_size(ref, @sizeOf(php.zend_reference));
}

pub fn ZVAL_COPY_DEREF(z: *php.zval, v: *php.zval) void {
    var tmp = v;
    if (php.Z_OPT_REFCOUNTED_P(v)) {
        if (php.Z_OPT_ISREF_P(v)) {
            tmp = php.Z_REFVAL_P(v);
            if (php.Z_OPT_REFCOUNTED_P(tmp)) {
                php.Z_ADDREF_P(tmp);
            }
        } else {
            php.Z_ADDREF_P(tmp);
        }
    }
    php.ZVAL_COPY_VALUE(z, tmp);
}

pub fn SEPARATE_STRING(zv: *php.zval) void {
    if (php.Z_REFCOUNT_P(zv) > 1) {
        const str = php.Z_STR_P(zv);
        std.debug.assert(php.Z_REFCOUNTED_P(zv));
        std.debug.assert(!php.ZSTR_IS_INTERNED(str));
        php.ZVAL_NEW_STR(zv, php.zend_string_init(php.ZSTR_VAL(str), php.ZSTR_LEN(str), 0));
        php.GC_DELREF(str);
    }
}

pub fn SEPARATE_ARRAY(zv: *php.zval) void {
    const arr = php.Z_ARR_P(zv);
    if (php.GC_REFCOUNT(arr) > 1) {
        ZVAL_ARR(zv, php.zend_array_dup(arr));
        php.GC_TRY_DELREF(arr);
    }
}

pub fn SEPARATE_ZVAL_NOREF(zv: *php.zval) void {
    std.debug.assert(php.Z_TYPE_P(zv) != php.IS_REFERENCE);
    if (php.Z_TYPE_P(zv) == php.IS_ARRAY) {
        SEPARATE_ARRAY(zv);
    }
}

pub fn SEPARATE_ZVAL(zv: *php.zval) void {
    if (php.Z_ISREF_P(zv)) {
        const ref = php.Z_REF_P(zv);
        php.ZVAL_COPY_VALUE(zv, &ref.val);
        if (php.GC_DELREF(ref) == 0) {
            php.efree_size(ref, @sizeOf(php.zend_reference));
        } else if (php.Z_OPT_TYPE_P(zv) == php.IS_ARRAY) {
            ZVAL_ARR(zv, php.zend_array_dup(php.Z_ARR_P(zv)));
            return;
        } else if (php.Z_OPT_REFCOUNTED_P(zv)) {
            php.Z_ADDREF_P(zv);
            return;
        }
    }
    if (php.Z_TYPE_P(zv) == php.IS_ARRAY) {
        SEPARATE_ARRAY(zv);
    }
}
pub fn ZVAL_UNDEF(z: *php.zval) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_UNDEF;
}

pub fn ZVAL_NULL(z: *php.zval) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_NULL;
}

pub fn ZVAL_FALSE(z: *php.zval) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_FALSE;
}

pub fn ZVAL_TRUE(z: *php.zval) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_TRUE;
}

pub fn ZVAL_BOOL(z: *php.zval, b: bool) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = if (b) php.IS_TRUE else php.IS_FALSE;
}

pub fn ZVAL_LONG(z: *php.zval, l: c_long) void {
    const l_ptr = php.Z_LVAL_P(z);
    l_ptr.* = l;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_LONG;
}

pub fn ZVAL_DOUBLE(z: *php.zval, d: f64) void {
    const d_ptr = php.Z_DVAL_P(z);
    d_ptr.* = d;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_DOUBLE;
}

pub fn ZVAL_STR(z: *php.zval, s: *php.zend_string) void {
    const str_ptr = php.Z_STR_P(z);
    str_ptr.* = s;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = if (php.ZSTR_IS_INTERNED(s)) php.IS_INTERNED_STRING_EX else php.IS_STRING_EX;
}

pub fn ZVAL_INTERNED_STR(z: *php.zval, s: *php.zend_string) void {
    const str_ptr = php.Z_STR_P(z);
    str_ptr.* = s;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_INTERNED_STRING_EX;
}

pub fn ZVAL_NEW_STR(z: *php.zval, s: *php.zend_string) void {
    const str_ptr = php.Z_STR_P(z);
    str_ptr.* = s;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_STRING_EX;
}

pub fn ZVAL_STR_COPY(z: *php.zval, s: *php.zend_string) void {
    const str_ptr = php.Z_STR_P(z);
    str_ptr.* = s;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    if (php.ZSTR_IS_INTERNED(s)) {
        z_ptr.* = php.IS_INTERNED_STRING_EX;
    } else {
        php.GC_ADDREF(s);
        z_ptr.* = php.IS_STRING_EX;
    }
}

pub fn ZVAL_ARR(z: *php.zval, a: *php.zend_array) void {
    const arr_ptr = php.Z_ARR_P(z);
    arr_ptr.* = a.*;
    z.u1.type_info = php.IS_ARRAY_EX;
}

pub fn ZVAL_NEW_PERSISTENT_ARR(z: *php.zval) void {
    const arr: *php.zend_array = php.malloc(@sizeOf(php.zend_array));
    const arr_ptr = php.Z_ARR_P(z);
    arr_ptr.* = arr;
    z.u1.type_info = php.IS_ARRAY_EX;
}

pub fn ZVAL_OBJ(z: *php.zval, o: *php.zend_object) void {
    const obj_ptr = php.Z_OBJ_P(z);
    obj_ptr.* = o;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_OBJECT_EX;
}

pub fn ZVAL_OBJ_COPY(z: *php.zval, o: *php.zend_object) void {
    php.GC_ADDREF(o);
    const obj_ptr = php.Z_OBJ_P(z);
    obj_ptr.* = o;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_OBJECT_EX;
}

pub fn ZVAL_RES(z: *php.zval, r: *php.zend_resource) void {
    const res_ptr = php.Z_RES_P(z);
    res_ptr.* = r;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_RESOURCE_EX;
}

pub fn ZVAL_NEW_RES(z: *php.zval, h: c_int, p: anyopaque, t: c_int) void {
    var res: *php.zend_resource = php.emalloc(@sizeOf(php.zend_resource));
    php.GC_SET_REFCOUNT(res, 1);
    const res_type_info = php.GC_TYPE_INFO(res);
    res_type_info.* = php.GC_RESOURCE;
    res.handle = h;
    res.ptr = p;
    res.type = t;
    const res_ptr = php.Z_RES_P(z);
    res_ptr.* = res;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_RESOURCE_EX;
}

pub fn ZVAL_NEW_PERSISTENT_RES(z: *php.zval, h: c_int, p: anyopaque, t: c_int) void {
    var res: *php.zend_resource = php.malloc(@sizeOf(php.zend_resource));
    php.GC_SET_REFCOUNT(res, 1);
    const res_type_info = php.GC_TYPE_INFO(res);
    res_type_info.* = php.GC_RESOURCE | (php.GC_PERSISTENT << php.GC_FLAGS_SHIFT);
    res.handle = h;
    res.ptr = p;
    res.type = t;
    const res_ptr = php.Z_RES_P(z);
    res_ptr.* = res;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_RESOURCE_EX;
}

pub fn ZVAL_REF(z: *php.zval, r: *php.zend_reference) void {
    const ref_ptr = php.Z_REF_P(z);
    ref_ptr.* = r;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_REFERENCE_EX;
}

pub fn ZVAL_NEW_EMPTY_REF(z: *php.zval) void {
    var ref: *php.zend_reference = php.emalloc(@sizeOf(php.zend_reference));
    php.GC_SET_REFCOUNT(ref, 1);
    const ref_type_info = php.GC_TYPE_INFO(ref);
    ref_type_info.* = php.GC_REFERENCE;
    ref.sources.ptr = null;
    const ref_ptr = php.Z_REF_P(z);
    ref_ptr.* = ref;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_REFERENCE_EX;
}

pub fn ZVAL_NEW_REF(z: *php.zval, r: *php.zval) void {
    var ref: *php.zend_reference = php.emalloc(@sizeOf(php.zend_reference));
    php.GC_SET_REFCOUNT(ref, 1);
    const ref_type_info = php.GC_TYPE_INFO(ref);
    ref_type_info.* = php.GC_REFERENCE;
    php.ZVAL_COPY_VALUE(&ref.val, r);
    ref.sources.ptr = null;
    const ref_ptr = php.Z_REF_P(z);
    ref_ptr.* = ref;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_REFERENCE_EX;
}

pub fn ZVAL_MAKE_REF_EX(z: *php.zval, refcount: c_int) void {
    var ref: *php.zend_reference = php.emalloc(@sizeOf(php.zend_reference));
    php.GC_SET_REFCOUNT(ref, refcount);
    const ref_type_info = php.GC_TYPE_INFO(ref);
    ref_type_info.* = php.GC_REFERENCE;
    php.ZVAL_COPY_VALUE(&ref.val, z);
    ref.sources.ptr = null;
    const ref_ptr = php.Z_REF_P(z);
    ref_ptr.* = ref;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_REFERENCE_EX;
}

pub fn ZVAL_NEW_PERSISTENT_REF(z: *php.zval, r: *php.zval) void {
    var ref: *php.zend_reference = php.malloc(@sizeOf(php.zend_reference));
    php.GC_SET_REFCOUNT(ref, 1);
    const ref_type_info = php.GC_TYPE_INFO(ref);
    ref_type_info.* = php.GC_REFERENCE | (php.GC_PERSISTENT << php.GC_FLAGS_SHIFT);
    php.ZVAL_COPY_VALUE(&ref.val, r);
    ref.sources.ptr = null;
    const ref_ptr = php.Z_REF_P(z);
    ref_ptr.* = ref;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_REFERENCE_EX;
}

pub fn ZVAL_AST(z: *php.zval, ast: *php.zend_ast) void {
    const ast_ptr = php.Z_AST_P(z);
    ast_ptr.* = ast;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_CONSTANT_AST_EX;
}

pub fn ZVAL_INDIRECT(z: *php.zval, v: *php.zval) void {
    const indirect_ptr = php.Z_INDIRECT_P(z);
    indirect_ptr.* = v;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_INDIRECT;
}

pub fn ZVAL_PTR(z: *php.zval, p: anyopaque) void {
    const ptr_ptr = php.Z_PTR_P(z);
    ptr_ptr.* = p;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_PTR;
}

pub fn ZVAL_FUNC(z: *php.zval, f: *php.zend_function) void {
    const func_ptr = php.Z_FUNC_P(z);
    func_ptr.* = f;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_PTR;
}

pub fn ZVAL_CE(z: *php.zval, c: *php.zend_class_entry) void {
    const ce_ptr = php.Z_CE_P(z);
    ce_ptr.* = c;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_PTR;
}

pub fn ZVAL_ALIAS_PTR(z: *php.zval, p: anyopaque) void {
    const alias_ptr = php.Z_PTR_P(z);
    alias_ptr.* = p;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_ALIAS_PTR;
}

pub fn ZVAL_ERROR(z: *php.zval) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php._IS_ERROR;
}
