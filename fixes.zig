pub const struct_zend_atomic_bool_s = extern struct {
    value: @import("std").atomic.Value(bool),
};
pub const zend_atomic_bool = struct_zend_atomic_bool_s;
