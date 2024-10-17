const std = @import("std");

const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

pub inline fn zval_get_type(pz: *const php.zval) *u8 {
    return @as(*u8, @constCast(&pz.u1.v.type));
}

pub inline fn Z_NEXT(zval_1: anytype) *@TypeOf(zval_1.u2.next) {
    _ = &zval_1;
    return &zval_1.u2.next;
}

pub inline fn Z_TYPE(zval: php.zval) *u8 {
    return zval_get_type(&zval);
}

pub inline fn Z_TYPE_P(zval_p: *php.zval) *u8 {
    return Z_TYPE(zval_p.*);
}

pub inline fn Z_TYPE_INFO(zval: *php.zval) *u32 {
    return &zval.u1.type_info;
}

pub inline fn Z_TYPE_INFO_P(zval_p: *php.zval) *u32 {
    return Z_TYPE_INFO(zval_p);
}

pub inline fn Z_TYPE_FLAGS(zval: php.zval) *u32 {
    return @as(*u32, @ptrCast(&zval.u1.v.type_flags));
}

pub inline fn Z_TYPE_FLAGS_P(zval_p: *php.zval) *u32 {
    return Z_TYPE_FLAGS(zval_p.*);
}

pub inline fn Z_CONSTANT(zval: php.zval) bool {
    return Z_TYPE(zval) == php.IS_CONSTANT_AST;
}

pub inline fn Z_CONSTANT_P(zval_p: *php.zval) bool {
    return Z_CONSTANT(zval_p.*);
}

pub inline fn Z_REFCOUNTED(zval: php.zval) bool {
    return Z_TYPE_FLAGS(zval) != 0;
}

pub inline fn Z_REFCOUNTED_P(zval_p: *php.zval) bool {
    return Z_REFCOUNTED(zval_p.*);
}

pub inline fn Z_COLLECTABLE(zval: php.zval) bool {
    return (Z_TYPE_FLAGS(zval) & php.IS_TYPE_COLLECTABLE) != 0;
}

pub inline fn Z_COLLECTABLE_P(zval_p: *php.zval) bool {
    return Z_COLLECTABLE(zval_p.*);
}

pub inline fn Z_COPYABLE(zval: php.zval) bool {
    return Z_TYPE(zval) == php.IS_ARRAY;
}

pub inline fn Z_COPYABLE_P(zval_p: *php.zval) bool {
    return Z_COPYABLE(zval_p.*);
}

pub inline fn Z_IMMUTABLE(zval: php.zval) bool {
    return Z_TYPE_INFO(zval).* == php.IS_ARRAY;
}

pub inline fn Z_IMMUTABLE_P(zval_p: *php.zval) bool {
    return Z_IMMUTABLE(zval_p.*);
}

pub inline fn Z_OPT_TYPE(zval: php.zval) *u32 {
    const opt_type = @as(u32, @intCast(Z_TYPE_INFO(zval).* & php.Z_TYPE_MASK));
    return &@as(*const u32, &opt_type).*;
}

pub inline fn Z_OPT_TYPE_P(zval_p: *php.zval) *u32 {
    return Z_OPT_TYPE(zval_p.*);
}

pub inline fn Z_OPT_CONSTANT(zval: php.zval) bool {
    return Z_OPT_TYPE(zval) == php.IS_CONSTANT_AST;
}

pub inline fn Z_OPT_CONSTANT_P(zval_p: *php.zval) bool {
    return Z_OPT_CONSTANT(zval_p.*);
}

pub inline fn Z_OPT_REFCOUNTED(zval: php.zval) bool {
    return php.Z_TYPE_INFO_REFCOUNTED(Z_TYPE_INFO(zval).*);
}

pub inline fn Z_OPT_REFCOUNTED_P(zval_p: *php.zval) bool {
    return Z_OPT_REFCOUNTED(zval_p.*);
}

pub inline fn Z_OPT_COPYABLE(zval: php.zval) bool {
    return Z_OPT_TYPE(zval) == php.IS_ARRAY;
}

pub inline fn Z_OPT_COPYABLE_P(zval_p: *php.zval) bool {
    return Z_OPT_COPYABLE(zval_p.*);
}

pub inline fn Z_OPT_ISREF(zval: php.zval) bool {
    return Z_OPT_TYPE(zval) == php.IS_REFERENCE;
}

pub inline fn Z_OPT_ISREF_P(zval_p: *php.zval) bool {
    return Z_OPT_ISREF(zval_p.*);
}

pub inline fn Z_ISREF(zval: php.zval) bool {
    return Z_TYPE(zval) == php.IS_REFERENCE;
}

pub inline fn Z_ISREF_P(zval_p: *php.zval) bool {
    return Z_ISREF(zval_p.*);
}

pub inline fn Z_ISUNDEF(zval: php.zval) bool {
    return Z_TYPE(zval) == php.IS_UNDEF;
}

pub inline fn Z_ISUNDEF_P(zval_p: *php.zval) bool {
    return Z_ISUNDEF(zval_p.*);
}

pub inline fn Z_ISNULL(zval: php.zval) bool {
    return Z_TYPE(zval) == php.IS_NULL;
}

pub inline fn Z_ISNULL_P(zval_p: *php.zval) bool {
    return Z_ISNULL(zval_p.*);
}

pub inline fn Z_ISERROR(zval: php.zval) bool {
    return Z_TYPE(zval) == php._IS_ERROR;
}

pub inline fn Z_ISERROR_P(zval_p: *php.zval) bool {
    return Z_ISERROR(zval_p.*);
}

pub inline fn Z_LVAL(zval: php.zval) c_long {
    return zval.value.lval;
}

pub inline fn Z_LVAL_P(zval_p: *php.zval) c_long {
    return Z_LVAL(zval_p.*);
}

pub inline fn Z_DVAL(zval: php.zval) *f64 {
    return &zval.value.dval;
}

pub inline fn Z_DVAL_P(zval_p: *php.zval) *f64 {
    return &zval_p.*.value.dval;
}

pub inline fn Z_STR(zval: php.zval) *[*c]php.zend_string {
    return &zval.value.str;
}

pub inline fn Z_STR_P(zval_p: *php.zval) *[*c]php.zend_string {
    return &(zval_p.*.value.str);
}

pub inline fn ZSTR_VAL(zstr: *php.zend_string) *@TypeOf(zstr.*.val) {
    return &zstr.*.val;
}

pub inline fn Z_STRVAL(zval: php.zval) *[*c]u8 {
    return ZSTR_VAL(Z_STR(zval));
}

pub inline fn Z_STRVAL_P(zval_p: *php.zval) [*c]u8 {
    return Z_STRVAL(zval_p.*);
}

pub inline fn Z_STRLEN(zval: php.zval) usize {
    return php.ZSTR_LEN(Z_STR(zval));
}

pub inline fn Z_STRLEN_P(zval_p: *php.zval) usize {
    return Z_STRLEN(zval_p.*);
}

pub inline fn Z_STRHASH(zval: php.zval) u64 {
    return php.ZSTR_HASH(Z_STR(zval));
}

pub inline fn Z_STRHASH_P(zval_p: *php.zval) u64 {
    return Z_STRHASH(zval_p.*);
}

pub inline fn Z_ARR(zval: php.zval) *php.zend_array {
    return zval.value.arr;
}

pub inline fn Z_ARR_P(zval_p: *php.zval) *php.zend_array {
    return Z_ARR(zval_p.*);
}

pub inline fn Z_ARRVAL(zval: php.zval) *php.zend_array {
    return Z_ARR(zval);
}

pub inline fn Z_ARRVAL_P(zval_p: *php.zval) *php.zend_array {
    return Z_ARRVAL(zval_p.*);
}

pub inline fn Z_OBJ(zval: php.zval) *php.zend_object {
    return zval.value.obj;
}

pub inline fn Z_OBJ_P(zval_p: *php.zval) *php.zend_object {
    return Z_OBJ(zval_p.*);
}

pub inline fn Z_OBJ_HT(zval: php.zval) *const php.zend_object_handlers {
    return Z_OBJ(zval).handlers;
}

pub inline fn Z_OBJ_HT_P(zval_p: *php.zval) *const php.zend_object_handlers {
    return Z_OBJ_HT(zval_p.*);
}

pub inline fn Z_OBJ_HANDLER(zval: php.zval, hf: anytype) @TypeOf(Z_OBJ_HT(zval).*[hf]) {
    return Z_OBJ_HT(zval).*[hf];
}

pub inline fn Z_OBJ_HANDLER_P(zv_p: *php.zval, hf: anytype) @TypeOf(Z_OBJ_HANDLER(zv_p.*, hf)) {
    return Z_OBJ_HANDLER(zv_p.*, hf);
}

pub inline fn Z_OBJ_HANDLE(zval: php.zval) u32 {
    return Z_OBJ(zval).handle;
}

pub inline fn Z_OBJ_HANDLE_P(zval_p: *php.zval) u32 {
    return Z_OBJ_HANDLE(zval_p.*);
}

pub inline fn Z_OBJCE(zval: php.zval) *php.zend_class_entry {
    return Z_OBJ(zval).ce;
}

pub inline fn Z_OBJCE_P(zval_p: *php.zval) *php.zend_class_entry {
    return Z_OBJCE(zval_p.*);
}

pub inline fn Z_OBJPROP(zval: php.zval) *php.zend_array {
    return Z_OBJ_HT(zval).get_properties.?(Z_OBJ(zval));
}

pub inline fn Z_OBJPROP_P(zval_p: *php.zval) *php.zend_array {
    return Z_OBJPROP(zval_p.*);
}

pub inline fn Z_RES(zval: php.zval) *php.zend_resource {
    return zval.value.res;
}

pub inline fn Z_RES_P(zval_p: *php.zval) *php.zend_resource {
    return Z_RES(zval_p.*);
}

pub inline fn Z_RES_HANDLE(zval: php.zval) u64 {
    return Z_RES(zval).handle;
}

pub inline fn Z_RES_HANDLE_P(zval_p: *php.zval) u64 {
    return Z_RES_HANDLE(zval_p.*);
}

pub inline fn Z_RES_TYPE(zval: php.zval) i32 {
    return Z_RES(zval).type;
}

pub inline fn Z_RES_TYPE_P(zval_p: *php.zval) i32 {
    return Z_RES_TYPE(zval_p.*);
}

pub inline fn Z_RES_VAL(zval: php.zval) ?*anyopaque {
    return Z_RES(zval).ptr;
}

pub inline fn Z_RES_VAL_P(zval_p: *php.zval) ?*anyopaque {
    return Z_RES_VAL(zval_p.*);
}

pub inline fn Z_REF(zval: php.zval) *php.zend_reference {
    return zval.value.ref;
}

pub inline fn Z_REF_P(zval_p: *php.zval) *php.zend_reference {
    return Z_REF(zval_p.*);
}

pub inline fn Z_REFVAL(zval: php.zval) *php.zval {
    return &Z_REF(zval).val;
}

pub inline fn Z_REFVAL_P(zval_p: *php.zval) *php.zval {
    return Z_REFVAL(zval_p.*);
}

pub inline fn Z_AST(zval: php.zval) *php.zend_ast_ref {
    return zval.value.ast;
}

pub inline fn Z_AST_P(zval_p: *php.zval) *php.zend_ast_ref {
    return Z_AST(zval_p.*);
}

pub inline fn GC_AST(p: *php.zend_ast_ref) *php.zend_ast {
    return @as(*php.zend_ast, @ptrCast(@as([*]u8, @ptrCast(p)) + @sizeOf(php.zend_ast_ref)));
}

pub inline fn Z_ASTVAL(zval: php.zval) *php.zend_ast {
    return GC_AST(Z_AST(zval));
}

pub inline fn Z_ASTVAL_P(zval_p: *php.zval) *php.zend_ast {
    return Z_ASTVAL(zval_p.*);
}

pub inline fn Z_INDIRECT(zval: php.zval) *php.zval {
    return &zval.value.zv;
}

pub inline fn Z_INDIRECT_P(zval_p: *php.zval) *php.zval {
    return Z_INDIRECT(zval_p.*);
}

pub inline fn Z_CE(zval: php.zval) *php.zend_class_entry {
    return zval.value.ce;
}

pub inline fn Z_CE_P(zval_p: *php.zval) *php.zend_class_entry {
    return Z_CE(zval_p.*);
}

pub inline fn Z_FUNC(zval: php.zval) *php.zend_function {
    return zval.value.func;
}

pub inline fn Z_FUNC_P(zval_p: *php.zval) *php.zend_function {
    return Z_FUNC(zval_p.*);
}

pub inline fn Z_PTR(zval: php.zval) ?*anyopaque {
    return zval.value.ptr;
}

pub inline fn Z_PTR_P(zval_p: *php.zval) ?*anyopaque {
    return Z_PTR(zval_p.*);
}

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
    Z_TYPE_INFO_P(z).* = php.IS_UNDEF;
}

pub fn ZVAL_NULL(z: *php.zval) void {
    Z_TYPE_INFO_P(z).* = php.IS_NULL;
}

pub fn ZVAL_FALSE(z: *php.zval) void {
    Z_TYPE_INFO_P(z).* = php.IS_FALSE;
}

pub fn ZVAL_TRUE(z: *php.zval) void {
    Z_TYPE_INFO_P(z).* = php.IS_TRUE;
}

pub fn ZVAL_BOOL(z: *php.zval, b: bool) void {
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = if (b) php.IS_TRUE else php.IS_FALSE;
}

pub fn ZVAL_LONG(z: *php.zval, l: c_long) void {
    Z_LVAL_P(z).* = l;
    Z_TYPE_INFO_P(z).* = php.IS_LONG;
}

pub fn ZVAL_DOUBLE(z: *php.zval, d: f64) void {
    Z_DVAL_P(z).* = d;
    Z_TYPE_INFO_P(z).* = php.IS_DOUBLE;
}

pub fn ZVAL_STR(z: *php.zval, s: *php.zend_string) void {
    Z_STR_P(z).* = s;
    Z_TYPE_INFO_P(z).* = if (php.ZSTR_IS_INTERNED(s) != 0) php.IS_INTERNED_STRING_EX else php.IS_STRING_EX;
}

pub fn ZVAL_INTERNED_STR(z: *php.zval, s: *php.zend_string) void {
    Z_STR_P(z).* = s;
    Z_TYPE_INFO_P(z).* = php.IS_INTERNED_STRING_EX;
}

pub fn ZVAL_NEW_STR(z: *php.zval, s: *php.zend_string) void {
    const str_ptr = Z_STR_P(z);
    str_ptr.* = s;
    const z_ptr = php.Z_TYPE_INFO_P(z);
    z_ptr.* = php.IS_STRING_EX;
}

pub fn ZVAL_STR_COPY(z: *php.zval, s: *php.zend_string) void {
    const str_ptr = Z_STR_P(z);
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
    const arr_ptr = Z_ARR_P(z);
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

pub fn Z_TRY_ADDREF_P(pz: *php.zval) void {
    if (Z_REFCOUNTED_P(pz)) {
        Z_ADDREF_P(pz);
    }
}

pub fn Z_ADDREF_P(pz: *php.zval) void {
    php.zval_addref_p(pz);
}

pub fn Z_TRY_ADDREF(z: php.zval) void {
    Z_TRY_ADDREF_P(&z);
}
