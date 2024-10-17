const std = @import("std");
const allocator = std.heap.page_allocator;

const config = @cImport({
    @cInclude("php_config.h");
    @cInclude("config.h");
});

const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

const zend = @import("zend.zig");

const Vector3 = extern struct {
    x: f64,
    y: f64,
    z: f64,
};

pub const php_raylib_vector3_object = extern struct {
    vector3: Vector3,
    prop_handler: *php.HashTable,
    std: php.zend_object,
};

pub fn Z_OBJ_P(zv: *php.zval) *php.zend_object {
    return php.Z_OBJ_P(zv);
}

pub fn Z_VECTOR3_OBJ_P(zv: *php.zval) *php_raylib_vector3_object {
    return php_raylib_vector3_fetch_object(Z_OBJ_P(zv));
}

pub var php_raylib_vector3_ce: ?*php.zend_class_entry = null;
pub var php_raylib_vector3_object_handlers: php.zend_object_handlers = undefined;
pub var php_raylib_vector3_prop_handlers: php.HashTable = undefined;

pub const raylib_vector3_read_float_t = fn (obj: *php_raylib_vector3_object, retval: *php.zval) c_int;
pub const raylib_vector3_write_float_t = fn (obj: *php_raylib_vector3_object, value: *php.zval) c_int;

pub const raylib_vector3_prop_handler = extern struct {
    read_float_func: ?*const raylib_vector3_read_float_t,
    write_float_func: ?*const raylib_vector3_write_float_t,
};

pub fn php_raylib_vector3_get_property_ptr_ptr(object: [*c]php.zend_object, name: [*c]php.zend_string, prop_type: c_int, cache_slot: [*c]?*anyopaque) callconv(.C) *php.zval {
    const obj: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(object);
    var retval: php.zval = undefined;
    var hnd: ?*raylib_vector3_prop_handler = null;

    if (@intFromPtr(obj.prop_handler) != 0) {
        const raw_ptr = php.zend_hash_find_ptr(obj.prop_handler, name);
        if (raw_ptr != null) {
            hnd = @alignCast(@ptrCast(raw_ptr));
            if (hnd) |valid_hnd| {
                if (php.zend_string_equals_literal(name, "x") or
                    php.zend_string_equals_literal(name, "y") or
                    php.zend_string_equals_literal(name, "z"))
                {
                    return php_raylib_vector3_property_reader(obj, valid_hnd, &retval);
                }

                return zend.EG(zend.ExecutorGlobalField.UNINITIALIZED_ZVAL);
            }
        }
    }

    if (hnd == null) {
        return php.zend_std_get_property_ptr_ptr(object, name, prop_type, cache_slot);
    }

    return &retval;
}

pub fn php_raylib_vector3_read_property(object: [*c]php.zend_object, name: [*c]php.zend_string, prop_type: c_int, cache_slot: [*c]?*anyopaque, rv: [*c]php.zval) callconv(.C) *php.zval {
    const obj: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(object);
    var retval: *php.zval = undefined;
    var hnd: ?*raylib_vector3_prop_handler = null;

    const raw_ptr = php.zend_hash_find_ptr(obj.prop_handler, name);
    if (raw_ptr != null) {
        hnd = @alignCast(@ptrCast(raw_ptr));
    }

    if (hnd) |hnd_safe| {
        retval = php_raylib_vector3_property_reader(obj, hnd_safe, rv);
    } else {
        retval = php.zend_std_read_property(object, name, prop_type, cache_slot, rv);
    }

    return retval;
}

pub fn php_raylib_vector3_write_property(object: [*c]php.zend_object, member: [*c]php.zend_string, value: [*c]php.zval, cache_slot: [*c]?*anyopaque) callconv(.C) *php.zval {
    const obj: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(object);
    var hnd: ?*raylib_vector3_prop_handler = null;

    const raw_ptr = php.zend_hash_find_ptr(obj.prop_handler, member);
    if (raw_ptr != null) {
        hnd = @alignCast(@ptrCast(raw_ptr));
    }

    if (hnd) |hnd_safe| {
        if (hnd_safe.write_float_func) |write_fn| {
            _ = write_fn(obj, value);
        }
    } else {
        return php.zend_std_write_property(object, member, value, cache_slot);
    }

    return value;
}

pub fn php_raylib_vector3_has_property(object: [*c]php.zend_object, name: [*c]php.zend_string, has_set_exists: c_int, cache_slot: [*c]?*anyopaque) callconv(.C) c_int {
    const obj: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(object);
    var hnd: ?*raylib_vector3_prop_handler = null;
    var ret: c_int = 0;

    const raw_ptr = php.zend_hash_find_ptr(obj.prop_handler, name);
    if (raw_ptr != null) {
        hnd = @alignCast(@ptrCast(raw_ptr));
    }

    if (hnd != null) {
        switch (has_set_exists) {
            php.ZEND_PROPERTY_EXISTS => ret = 1,
            php.ZEND_PROPERTY_NOT_EMPTY => {
                var rv: php.zval = undefined;
                const value: *php.zval = php_raylib_vector3_read_property(object, name, php.BP_VAR_IS, cache_slot, &rv);

                if (value != zend.EG(zend.ExecutorGlobalField.UNINITIALIZED_ZVAL)) {
                    php.convert_to_boolean(value);
                    ret = if (zend.Z_TYPE_P(value).* == php.IS_TRUE) 1 else 0;
                }
            },
            php.ZEND_PROPERTY_ISSET => {
                var rv: php.zval = undefined;
                const value: *php.zval = php_raylib_vector3_read_property(object, name, php.BP_VAR_IS, cache_slot, &rv);
                if (value != zend.EG(zend.ExecutorGlobalField.UNINITIALIZED_ZVAL)) {
                    ret = if (zend.Z_TYPE_P(value).* != php.IS_NULL) 1 else 0;
                    php.zval_ptr_dtor(value);
                }
            },
            else => {},
        }
    } else {
        ret = php.zend_std_has_property(object, name, has_set_exists, cache_slot);
    }

    return ret;
}

pub fn php_raylib_vector3_get_gc(object: [*c]php.zend_object, gc_data: [*c][*c]php.zval, gc_data_count: [*c]c_int) callconv(.C) *php.HashTable {
    gc_data.* = undefined;
    gc_data_count.* = 0;
    return php.zend_std_get_properties(object);
}

pub fn php_raylib_vector3_get_properties(object: [*c]php.zend_object) callconv(.C) *php.HashTable {
    std.debug.print("Vector3.php_raylib_vector3_get_properties called\n", .{});

    const obj: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(object);
    const props: *php.HashTable = php.zend_std_get_properties(object);
    const hnd: ?*raylib_vector3_prop_handler = null;

    var iter = struct {
        const Self = @This();

        obj: *php_raylib_vector3_object,
        props: *php.HashTable,
        hnd: ?*raylib_vector3_prop_handler,

        fn call(self: *anyopaque, key: ?*php.zend_string, ptr: ?*anyopaque) void {
            const this: *Self = @alignCast(@ptrCast(self));

            var ret: ?*php.zval = null;
            var val_zval: php.zval = undefined;

            if (ptr) |raw_ptr| {
                this.hnd = @alignCast(@ptrCast(raw_ptr));
            }
            if (this.hnd) |raw_hnd| {
                ret = php_raylib_vector3_property_reader(this.obj, raw_hnd, &val_zval);
                if (ret == null) {
                    ret = zend.EG(zend.ExecutorGlobalField.UNINITIALIZED_ZVAL);
                }

                _ = php.zend_hash_update(this.props, key, ret);
            }
        }
    }{ .obj = obj, .props = props, .hnd = hnd };

    zend.ZEND_HASH_FOREACH_STR_KEY_PTR(obj.prop_handler, @ptrCast(&iter), @constCast(&@TypeOf(iter).call));

    return props;
}

pub fn php_raylib_vector3_free_prop_handler(el: [*c]php.zval) callconv(.C) void {
    std.debug.print("Vector3.php_raylib_vector3_free_prop_handler called\n", .{});
    php.pefree(zend.Z_PTR_P(el), true);
}

pub fn php_raylib_vector3_register_prop_handler(prop_handler: *php.HashTable, name: [*c]const u8, read_float_func: ?raylib_vector3_read_float_t, write_float_func: ?raylib_vector3_write_float_t) void {
    std.debug.print("Vector3.php_raylib_vector3_register_prop_handler called\n", .{});

    var hnd = raylib_vector3_prop_handler{
        .read_float_func = if (read_float_func) |f| &f else null,
        .write_float_func = if (write_float_func) |f| &f else null,
    };

    // Add the handler to the hash table
    _ = php.zend_hash_str_add_mem(prop_handler, name, std.mem.len(name), &hnd, @sizeOf(raylib_vector3_prop_handler));

    // Register for reflection
    php.zend_declare_property_null(php_raylib_vector3_ce, name, std.mem.len(name), php.ZEND_ACC_PUBLIC);
}

pub fn php_raylib_vector3_property_reader(obj: *php_raylib_vector3_object, hnd: *raylib_vector3_prop_handler, rv: *php.zval) *php.zval {
    std.debug.print("Vector3.php_raylib_vector3_property_reader called\n", .{});

    if (hnd.read_float_func) |read_float_func| {
        _ = read_float_func(obj, rv);
    }
    return rv;
}

pub fn php_raylib_vector3_free_storage(object: [*c]php.zend_object) callconv(.C) void {
    std.debug.print("Vector3.php_raylib_vector3_free_storage called\n", .{});

    const intern: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(object);
    php.zend_object_std_dtor(&intern.std);
}

pub fn php_raylib_vector3_new_ex(ce: *php.zend_class_entry, orig: ?*php.zend_object) !*php.zend_object {
    std.debug.print("Vector3.php_raylib_vector3_new_ex called\n", .{});

    const raw_intern: ?*anyopaque = php.zend_object_alloc(@sizeOf(php_raylib_vector3_object), ce);
    if (raw_intern == null) {
        // Handle error, maybe return null or panic depending on your application logic
        std.debug.print("Vector3.php_raylib_vector3_new_ex allocation failed\n", .{});
        return error.AllocationFailed;
    }

    // Cast the unwrapped optional to the correct type
    var intern: *php_raylib_vector3_object = @alignCast(@ptrCast(raw_intern));

    intern.prop_handler = &php_raylib_vector3_prop_handlers;

    if (orig) |orig_obj| {
        const other: *php_raylib_vector3_object = php_raylib_vector3_fetch_object(orig_obj);

        intern.vector3 = Vector3{
            .x = other.vector3.x,
            .y = other.vector3.y,
            .z = other.vector3.z,
        };
    } else {
        intern.vector3 = Vector3{
            .x = 0,
            .y = 0,
            .z = 0,
        };
    }

    php.zend_object_std_init(&intern.std, ce);
    php.object_properties_init(&intern.std, ce);
    intern.std.handlers = &php_raylib_vector3_object_handlers;

    return &intern.std;
}

pub fn php_raylib_vector3_new(class_type: [*c]php.zend_class_entry) callconv(.C) [*c]php.zend_object {
    std.debug.print("Vector3.php_raylib_vector3_new called\n", .{});
    return php_raylib_vector3_new_ex(class_type, null) catch {
        @panic("Failed to create new Vector3 object");
    };
}

pub fn php_raylib_vector3_clone(old_object: [*c]php.zend_object) callconv(.C) *php.zend_object {
    std.debug.print("Vector3.php_raylib_vector3_clone called\n", .{});

    const old_object_ref: *php.zend_object = @ptrCast(old_object);
    const old_ce = old_object_ref.ce;

    // Create a new object by calling the custom "new" function
    const new_object: *php.zend_object = php_raylib_vector3_new_ex(old_ce, old_object) catch {
        return old_object;
    };

    // Clone the members of the old object to the new object
    php.zend_objects_clone_members(new_object, old_object);

    return new_object;
}

pub fn php_raylib_vector3_fetch_object(obj: *php.zend_object) *php_raylib_vector3_object {
    std.debug.print("Vector3.php_raylib_vector3_fetch_object called\n", .{});
    const offset: comptime_int = @offsetOf(php_raylib_vector3_object, "std");
    const ptr: *u8 = @ptrFromInt(@intFromPtr(obj) - offset);
    return @alignCast(@ptrCast(ptr));
}

var arginfo_vector3__construct: [4]php.zend_internal_arg_info = .{
    zend.ZEND_BEGIN_ARG_INFO_EX(0, 0, false),
    zend.ZEND_ARG_TYPE_MASK(false, "x", php.MAY_BE_DOUBLE | php.MAY_BE_NULL, "0"),
    zend.ZEND_ARG_TYPE_MASK(false, "y", php.MAY_BE_DOUBLE | php.MAY_BE_NULL, "0"),
    zend.ZEND_ARG_TYPE_MASK(false, "z", php.MAY_BE_DOUBLE | php.MAY_BE_NULL, "0"),
};
pub fn vector3__construct(execute_data: ?*php.zend_execute_data, _: ?*php.zval) callconv(.C) void {
    std.debug.print("Vector3.vector3__construct called\n", .{});

    var x: f64 = 0.0;
    var x_is_null: bool = true;

    var y: f64 = 0.0;
    var y_is_null: bool = true;

    var z: f64 = 0.0;
    var z_is_null: bool = true;

    var paramState = zend.ZEND_PARSE_PARAMETERS_START(0, 3, execute_data);
    zend.Z_PARAM_OPTIONAL(&paramState);
    _ = zend.Z_PARAM_DOUBLE_OR_NULL(&paramState, &x, &x_is_null) catch {};
    _ = zend.Z_PARAM_DOUBLE_OR_NULL(&paramState, &y, &y_is_null) catch {};
    _ = zend.Z_PARAM_DOUBLE_OR_NULL(&paramState, &z, &z_is_null) catch {};
    _ = zend.ZEND_PARSE_PARAMETERS_END(&paramState) catch {};

    var intern = Z_VECTOR3_OBJ_P(zend.EX(zend.ExecutorField.THIS));

    if (x_is_null) x = 0.0;
    if (y_is_null) y = 0.0;
    if (z_is_null) z = 0.0;

    std.debug.print("Vector3.vector3__construct -> x = {d}\n", .{x});
    std.debug.print("Vector3.vector3__construct -> y = {d}\n", .{y});
    std.debug.print("Vector3.vector3__construct -> z = {d}\n", .{z});

    intern.vector3 = Vector3{
        .x = x,
        .y = y,
        .z = z,
    };
}

fn php_raylib_vector3_get_x(obj: *php_raylib_vector3_object, retval: *php.zval) c_int {
    std.debug.print("Vector3.php_raylib_vector3_get_x called\n", .{});
    zend.ZVAL_DOUBLE(retval, obj.vector3.x);

    if (php.Z_REFCOUNTED(retval)) {
        _ = php.Z_ADDREF_P(retval);
    }

    return php.SUCCESS;
}

fn php_raylib_vector3_get_y(obj: *php_raylib_vector3_object, retval: *php.zval) c_int {
    std.debug.print("Vector3.php_raylib_vector3_get_y called\n", .{});
    zend.ZVAL_DOUBLE(retval, obj.vector3.y);

    if (php.Z_REFCOUNTED(retval)) {
        _ = php.Z_ADDREF_P(retval);
    }

    return php.SUCCESS;
}

fn php_raylib_vector3_get_z(obj: *php_raylib_vector3_object, retval: *php.zval) c_int {
    std.debug.print("Vector3.php_raylib_vector3_get_z called\n", .{});
    zend.ZVAL_DOUBLE(retval, obj.vector3.z);

    if (php.Z_REFCOUNTED(retval)) {
        _ = php.Z_ADDREF_P(retval);
    }

    return php.SUCCESS;
}

fn php_raylib_vector3_set_x(obj: *php_raylib_vector3_object, newval: *php.zval) c_int {
    std.debug.print("Vector3.php_raylib_vector3_set_x called\n", .{});
    const ret = php.SUCCESS;

    if (zend.Z_TYPE_P(newval).* == php.IS_NULL) {
        obj.vector3.x = 0;
        return ret;
    }

    obj.vector3.x = php.zval_get_double(newval);
    std.debug.print("Vector3.x = {d}\n", .{obj.vector3.x});

    return ret;
}

fn php_raylib_vector3_set_y(obj: *php_raylib_vector3_object, newval: *php.zval) c_int {
    const ret = php.SUCCESS;

    if (zend.Z_TYPE_P(newval).* == php.IS_NULL) {
        obj.vector3.y = 0;
        return ret;
    }

    obj.vector3.y = php.zval_get_double(newval);
    std.debug.print("Vector3.x = {d}\n", .{obj.vector3.y});

    return ret;
}

fn php_raylib_vector3_set_z(obj: *php_raylib_vector3_object, newval: *php.zval) c_int {
    const ret = php.SUCCESS;

    if (zend.Z_TYPE_P(newval).* == php.IS_NULL) {
        obj.vector3.z = 0;
        return ret;
    }

    obj.vector3.z = php.zval_get_double(newval);
    std.debug.print("Vector3.x = {d}\n", .{obj.vector3.z});

    return ret;
}

var php_raylib_vector3_methods = [_]php.zend_function_entry{
    zend.PHP_ME("__construct", vector3__construct, &arginfo_vector3__construct, arginfo_vector3__construct.len - 1, php.ZEND_ACC_PUBLIC),
    zend.PHP_FE_END(),
};

pub fn php_raylib_vector3_startup(_: c_int, _: c_int) void {
    std.debug.print("Vector3.php_raylib_vector3_startup called\n", .{});
    var ce: php.zend_class_entry = undefined;

    // Copy standard object handlers
    _ = php.memcpy(
        &php_raylib_vector3_object_handlers,
        php.zend_get_std_object_handlers(),
        @sizeOf(php.zend_object_handlers),
    );

    // Set object handlers
    php_raylib_vector3_object_handlers.offset = @offsetOf(php_raylib_vector3_object, "std");
    php_raylib_vector3_object_handlers.free_obj = php_raylib_vector3_free_storage;
    php_raylib_vector3_object_handlers.clone_obj = php_raylib_vector3_clone;

    // Property handlers
    php_raylib_vector3_object_handlers.get_property_ptr_ptr = php_raylib_vector3_get_property_ptr_ptr;
    php_raylib_vector3_object_handlers.get_gc = php_raylib_vector3_get_gc;
    php_raylib_vector3_object_handlers.get_properties = php_raylib_vector3_get_properties;
    php_raylib_vector3_object_handlers.read_property = php_raylib_vector3_read_property;
    php_raylib_vector3_object_handlers.write_property = php_raylib_vector3_write_property;
    php_raylib_vector3_object_handlers.has_property = php_raylib_vector3_has_property;

    // Initialize class entry
    zend.INIT_NS_CLASS_ENTRY(&ce, "raylib", "Vector3", @ptrCast(&php_raylib_vector3_methods));
    php_raylib_vector3_ce = php.zend_register_internal_class(&ce);
    if (php_raylib_vector3_ce) |raw_ce| {
        std.debug.print("Vector3.php_raylib_vector3_startup create_object assigned\n", .{});
        raw_ce.unnamed_1.create_object = php_raylib_vector3_new;
    }
    std.debug.print("Vector3.php_raylib_vector3_startup inialized {d} functions registered\n", .{php_raylib_vector3_ce.?.function_table.nNumUsed});

    // Initialize property handlers
    php.zend_hash_init(&php_raylib_vector3_prop_handlers, 0, null, php_raylib_vector3_free_prop_handler, true);

    // Register property handlers for x, y, z
    php_raylib_vector3_register_prop_handler(&php_raylib_vector3_prop_handlers, "x", php_raylib_vector3_get_x, php_raylib_vector3_set_x);
    php_raylib_vector3_register_prop_handler(&php_raylib_vector3_prop_handlers, "y", php_raylib_vector3_get_y, php_raylib_vector3_set_y);
    php_raylib_vector3_register_prop_handler(&php_raylib_vector3_prop_handlers, "z", php_raylib_vector3_get_z, php_raylib_vector3_set_z);
}
