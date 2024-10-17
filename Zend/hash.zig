const std = @import("std");

const php = @cImport({
    @cInclude("php_config.h");
    @cInclude("zend_API.h");
    @cInclude("php.h");
    @cInclude("ext/standard/info.h");
    @cInclude("wrapper.h");
});

pub const zend_atomic_bool = extern struct {
    value: std.atomic.Value(bool),
};

const types = @import("types.zig");

fn HT_FLAGS(ht: *php.HashTable) *u32 {
    return &ht.u.flags;
}

fn HT_IS_PACKED(ht: *php.HashTable) bool {
    return (HT_FLAGS(ht) & php.HASH_FLAG_PACKED) != 0;
}

fn ZEND_HASH_ELEMENT_SIZE(ht: *php.HashTable) usize {
    return @sizeOf(php.zval) + if (!HT_IS_PACKED(ht)) (@sizeOf(php.Bucket) - @sizeOf(php.zval)) else 0;
}

fn ZEND_HASH_ELEMENT_EX(ht: *php.HashTable, idx: usize, size: usize) ?*php.zval {
    return ht.arPacked orelse return null + idx * size;
}

fn ZEND_HASH_NEXT_ELEMENT(el: ?*php.zval, size: usize) ?*php.zval {
    return if (el) |elem| @as(*php.zval, @ptrCast(@as(*u8, @ptrCast(elem)) + size)) else null;
}

fn ZEND_HASH_PREV_ELEMENT(el: ?*php.zval, size: usize) ?*php.zval {
    return if (el) |elem| @as(*php.zval, @ptrCast(@as(*u8, @ptrCast(elem)) - size)) else null;
}

pub fn ZEND_HASH_FOREACH_VAL(ht: *php.HashTable, body: fn (*php.zval) void) void {
    var count: u32 = ht.nNumUsed;
    const size = ZEND_HASH_ELEMENT_SIZE(ht);
    var z = ht.arPacked;

    while (count > 0) : (count -= 1) {
        if (z and types.Z_TYPE_P(z) != php.IS_UNDEF) {
            body(z);
        }
        z = ZEND_HASH_NEXT_ELEMENT(z, size);
    }
}

pub fn ZEND_HASH_REVERSE_FOREACH_VAL(ht: *php.HashTable, body: fn (*php.zval) void) void {
    var idx: u32 = ht.nNumUsed;
    const size = ZEND_HASH_ELEMENT_SIZE(ht);
    var z = ZEND_HASH_ELEMENT_EX(ht, idx, size);

    while (idx > 0) : (idx -= 1) {
        z = ZEND_HASH_PREV_ELEMENT(z, size);
        if (z and types.Z_TYPE_P(z) != php.IS_UNDEF) {
            body(z);
        }
    }
}

pub fn ZEND_HASH_FOREACH_FROM(ht: *php.HashTable, indirect: bool, from: u32, body: fn (?*php.zend_string, *php.zval, usize) void) void {
    var idx: u32 = from;
    const size = ZEND_HASH_ELEMENT_SIZE(ht);
    var z = ZEND_HASH_ELEMENT_EX(ht, idx, size);
    var count: u32 = ht.nNumUsed - from;
    var key: ?*php.zend_string = null;
    var h: usize = 0;

    while (count > 0) : (count -= 1) {
        if (HT_IS_PACKED(ht)) {
            z += 1;
            h = idx;
            idx += 1;
        } else {
            var p = @as(*php.Bucket, @ptrCast(z));
            z = &p[1].val;
            h = p.h;
            key = p.key;

            if (indirect and types.Z_TYPE_P(z) == php.IS_INDIRECT) {
                z = php.Z_INDIRECT_P(z);
            }
        }

        if (types.Z_TYPE_P(z) != php.IS_UNDEF) {
            body(key, z, h);
        }
    }
}

pub fn ZEND_HASH_REVERSE_FOREACH(ht: *php.HashTable, indirect: bool, body: fn (?*php.zend_string, *php.zval, usize) void) void {
    var idx: u32 = ht.nNumUsed;
    const size = ZEND_HASH_ELEMENT_SIZE(ht);
    var z = ZEND_HASH_ELEMENT_EX(ht, idx, size);
    var key: ?*php.zend_string = null;
    var h: usize = 0;

    while (idx > 0) : (idx -= 1) {
        if (HT_IS_PACKED(ht)) {
            z -= 1;
            h = idx - 1;
        } else {
            var p = @as(*php.Bucket, @ptrCast(z));
            p -= 1;
            z = &p.val;
            h = p.h;
            key = p.key;

            if (indirect and types.Z_TYPE_P(z) == php.IS_INDIRECT) {
                z = php.Z_INDIRECT_P(z);
            }
        }

        if (types.Z_TYPE_P(z) != php.IS_UNDEF) {
            body(key, z, h);
        }
    }
}

// Function to simulate ZEND_HASH_FOREACH_STR_KEY_VAL macro
pub fn ZEND_HASH_FOREACH_STR_KEY_VAL(ht: *php.HashTable, body: fn (key: ?*php.zend_string, val: *php.zval) void) void {
    const size = ZEND_HASH_ELEMENT_SIZE(ht);
    var idx: u32 = 0;
    var el = ZEND_HASH_ELEMENT_EX(ht, idx, size);
    var count: u32 = ht.nNumUsed;

    while (count > 0) {
        const z = el;
        var key: ?*php.zend_string = null;
        var h: usize = 0;

        if (HT_IS_PACKED(ht)) {
            el = ZEND_HASH_NEXT_ELEMENT(el, size);
            h = idx;
            idx += 1;
        } else {
            var p = @as(*php.Bucket, @ptrCast(el));
            el = &p[1].val;
            h = p.h;
            key = p.key;
        }

        if (types.Z_TYPE_P(z) != php.IS_UNDEF) {
            body(key, z);
        }

        count -= 1;
    }
}

pub fn ZEND_HASH_MAP_REVERSE_FOREACH(ht: *php.HashTable, indirect: bool, body: fn (val: *php.zval) void) void {
    var idx: u32 = ht.nNumUsed;
    var p: *php.Bucket = ht.arData + idx;
    var z: *php.zval = undefined;

    // Ensure the hash table is not packed
    std.debug.assert(!HT_IS_PACKED(ht));

    while (idx > 0) : (idx -= 1) {
        p -= 1;
        z = &p.val;

        if (indirect and types.Z_TYPE_P(z) == php.IS_INDIRECT) {
            z = types.Z_INDIRECT_P(z);
        }

        if (types.Z_TYPE_P(z) == php.IS_UNDEF) {
            continue;
        }

        // Call the provided function (body) with the value (zval)
        body(z);
    }
}

pub fn ZEND_HASH_MAP_FOREACH_FROM(ht: *php.HashTable, indirect: bool, from: u32, context: *anyopaque, callback: fn (*anyopaque, *php.zval) void) void {
    const p = ht.unnamed_0.arData + from;
    const end = ht.unnamed_0.arData + ht.nNumUsed;

    // php.ZEND_ASSERT(!HT_IS_PACKED(ht));

    var current_p: [*]php.Bucket = @ptrCast(p);
    const end_p: [*]php.Bucket = @ptrCast(end);
    while (@intFromPtr(current_p) < @intFromPtr(end_p)) {
        var z: *php.zval = &current_p[0].val;
        if (indirect and types.Z_TYPE_P(z).* == php.IS_INDIRECT) {
            z = @as(*php.zval, @ptrCast(@alignCast(&z.value.zv)));
        }
        if (types.Z_TYPE_P(z).* != php.IS_UNDEF) {
            // Call the body function with the value
            callback(context, z);
        }
        current_p += 1;
    }
}

pub fn ZEND_HASH_MAP_FOREACH(ht: *php.HashTable, indirect: bool, context: *anyopaque, callback: *const fn (*anyopaque, ?*php.zval) void) void {
    const Iter = struct {
        context: *anyopaque,
        callback: *const fn (*anyopaque, ?*php.zval) void,

        fn call(self: *anyopaque, z: *php.zval) void {
            const this: *@This() = @alignCast(@ptrCast(self));
            this.callback(this.context, z);
        }
    };

    var iter = Iter{
        .context = context,
        .callback = callback,
    };

    ZEND_HASH_MAP_FOREACH_FROM(ht, indirect, 0, @ptrCast(&iter), Iter.call);
}

pub fn ZEND_HASH_MAP_FOREACH_END_DEL(ht: *php.HashTable, idx: u32, p: *php.Bucket) void {
    std.debug.assert(!HT_IS_PACKED(ht));

    ht.nNumOfElements -= 1;

    // Re-index the hash table
    const j: u32 = php.HT_IDX_TO_HASH(idx - 1);
    const nIndex: u32 = p.h | ht.nTableMask;
    var i: u32 = php.HT_HASH(ht, nIndex);

    if (j != i) {
        var prev: *php.Bucket = php.HT_HASH_TO_BUCKET(ht, i);
        while (types.Z_NEXT(prev.val) != j) {
            i = types.Z_NEXT(prev.val);
            prev = types.HT_HASH_TO_BUCKET(ht, i);
        }
        types.Z_NEXT(prev.val).* = types.Z_NEXT(p.val).*;
    } else {
        types.Z_NEXT(ht, nIndex).* = types.Z_NEXT(p.val).*;
    }

    ht.nNumUsed = idx;
}

// pub fn ZEND_HASH_MAP_FOREACH_BUCKET(ht: *php.HashTable, _bucket: *php.Bucket) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _bucket = _p;
// }

// pub fn ZEND_HASH_MAP_FOREACH_BUCKET_FROM(ht: *php.HashTable, _bucket: *php.Bucket, _from: u32) void {
//     ZEND_HASH_MAP_FOREACH_FROM(ht, 0, _from);
//     _bucket = _p;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_BUCKET(ht: *php.HashTable, _bucket: *php.Bucket) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _bucket = _p;
// }

// pub fn ZEND_HASH_MAP_FOREACH_VAL(ht: *php.HashTable, _val: *php.zval) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_VAL(ht: *php.HashTable, _val: *php.zval) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_FOREACH_VAL_IND(ht: *php.HashTable, _val: *php.zval) void {
//     ZEND_HASH_MAP_FOREACH(ht, 1);
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_VAL_IND(ht: *php.HashTable, _val: *php.zval) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 1);
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_FOREACH_PTR(ht: *php.HashTable, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _ptr = php.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_FOREACH_PTR_FROM(ht: *php.HashTable, _ptr: ?*anyopaque, _from: u32) void {
//     ZEND_HASH_MAP_FOREACH_FROM(ht, 0, _from);
//     _ptr = php.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_PTR(ht: *php.HashTable, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _ptr = php.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_FOREACH_NUM_KEY(ht: *php.HashTable, _h: u64) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _h = _p.h;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_NUM_KEY(ht: *php.HashTable, _h: u64) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _h = _p.h;
// }

// pub fn ZEND_HASH_MAP_FOREACH_STR_KEY(ht: *php.HashTable, _key: *php.zend_string) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _key = _p.key;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_STR_KEY(ht: *php.HashTable, _key: *php.zend_string) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _key = _p.key;
// }

// pub fn ZEND_HASH_MAP_FOREACH_KEY(ht: *php.HashTable, _h: u64, _key: *php.zend_string) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _h = _p.h;
//     _key = _p.key;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_KEY(ht: *php.HashTable, _h: u64, _key: *php.zend_string) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _h = _p.h;
//     _key = _p.key;
// }

// pub fn ZEND_HASH_MAP_FOREACH_NUM_KEY_VAL(ht: *php.HashTable, _h: u64, _val: *php.zval) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _h = _p.h;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_NUM_KEY_VAL(ht: *php.HashTable, _h: u64, _val: *php.zval) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _h = _p.h;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_FOREACH_STR_KEY_VAL(ht: *php.HashTable, _key: *php.zend_string, _val: *php.zval) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _key = _p.key;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_FOREACH_STR_KEY_VAL_FROM(ht: *php.HashTable, _key: *php.zend_string, _val: *php.zval, _from: u32) void {
//     ZEND_HASH_MAP_FOREACH_FROM(ht, 0, _from);
//     _key = _p.key;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_STR_KEY_VAL(ht: *php.HashTable, _key: *php.zend_string, _val: *php.zval) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _key = _p.key;
//     _val = _z;
// }

pub fn ZEND_HASH_MAP_FOREACH_KEY_VAL(ht: *php.HashTable, body: fn (h: u64, key: ?*php.zend_string, val: *php.zval) void) void {
    ZEND_HASH_MAP_FOREACH(ht, false, struct {
        const Self = @This();

        fn call(_: *Self, p: *php.Bucket, z: *php.zval) void {
            body(p.h, p.key, z);
        }
    }.call);
}

pub fn ZEND_HASH_MAP_REVERSE_FOREACH_KEY_VAL(ht: *php.HashTable, body: fn (h: u64, key: ?*php.zend_string, val: *php.zval) void) void {
    ZEND_HASH_MAP_REVERSE_FOREACH(ht, false, struct {
        const Self = @This();

        fn call(_: *Self, p: *php.Bucket, z: *php.zval) void {
            body(p.h, p.key, z);
        }
    }.call);
}

// pub fn ZEND_HASH_MAP_FOREACH_STR_KEY_VAL_IND(ht: *php.HashTable, _key: *php.zend_string, _val: *php.zval) void {
//     ZEND_HASH_MAP_FOREACH(ht, 1);
//     _key = _p.key;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_STR_KEY_VAL_IND(ht: *php.HashTable, _key: *php.zend_string, _val: *php.zval) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 1);
//     _key = _p.key;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_FOREACH_KEY_VAL_IND(ht: *php.HashTable, _h: u64, _key: *php.zend_string, _val: *php.zval) void {
//     ZEND_HASH_MAP_FOREACH(ht, 1);
//     _h = _p.h;
//     _key = _p.key;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_KEY_VAL_IND(ht: *php.HashTable, _h: u64, _key: *php.zend_string, _val: *php.zval) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 1);
//     _h = _p.h;
//     _key = _p.key;
//     _val = _z;
// }

// pub fn ZEND_HASH_MAP_FOREACH_NUM_KEY_PTR(ht: *php.HashTable, _h: u64, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _h = _p.h;
//     _ptr = types.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_NUM_KEY_PTR(ht: *php.HashTable, _h: u64, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _h = _p.h;
//     _ptr = types.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_FOREACH_STR_KEY_PTR(ht: *php.HashTable, body: fn (key: ?*php.zend_string, ptr: ?*anyopaque) void) void {
//     ZEND_HASH_MAP_FOREACH(ht, false, struct {
//         body_fn: fn (key: ?*php.zend_string, ptr: ?*anyopaque) void,

//         fn call(self: *Self, p: *php.Bucket, z: *php.zval) void {
//             const key: ?*php.zend_string = p.key;
//             const ptr: ?*anyopaque = types.Z_PTR_P(z);
//             self.body_fn(key, ptr); // Call the outer `body`
//         }
//     }.{ .body_fn = body }.call);
// }
pub const ForeachStrPtrKeyIterFn = fn (context: *anyopaque, key: ?*php.zend_string, ptr: ?*anyopaque) void;

pub const ForeachStrPtrKeyIter = struct {
    context: *anyopaque,
    callback: *const ForeachStrPtrKeyIterFn,

    fn call(self: *anyopaque, z: ?*php.zval) void {
        const this: *ForeachStrPtrKeyIter = @ptrCast(@alignCast(self));
        if (z) |zval| {
            const bucket: *php.Bucket = @ptrCast(@alignCast(zval));
            this.callback(this.context, bucket.key, php.Z_PTR_P(&bucket.val));
        }
    }
};

pub fn ZEND_HASH_FOREACH_STR_KEY_PTR(ht: *php.HashTable, context: *anyopaque, callback: *const ForeachStrPtrKeyIterFn) void {
    var iter = ForeachStrPtrKeyIter{
        .context = context,
        .callback = callback,
    };

    ZEND_HASH_MAP_FOREACH(ht, false, @ptrCast(&iter), @as(*const fn (*anyopaque, ?*php.zval) void, @ptrCast(&ForeachStrPtrKeyIter.call)));
}

// pub fn ZEND_HASH_MAP_FOREACH_STR_KEY_PTR(ht: *php.HashTable, _key: *php.zend_string, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _key = _p.key;
//     _ptr = types.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_STR_KEY_PTR(ht: *php.HashTable, _key: *php.zend_string, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _key = _p.key;
//     _ptr = types.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_FOREACH_KEY_PTR(ht: *php.HashTable, _h: u64, _key: *php.zend_string, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_FOREACH(ht, 0);
//     _h = _p.h;
//     _key = _p.key;
//     _ptr = php.Z_PTR_P(_z);
// }

// pub fn ZEND_HASH_MAP_REVERSE_FOREACH_KEY_PTR(ht: *php.HashTable, _h: u64, _key: *php.zend_string, _ptr: ?*anyopaque) void {
//     ZEND_HASH_MAP_REVERSE_FOREACH(ht, 0);
//     _h = _p.h;
//     _key = _p.key;
//     _ptr = php.Z_PTR_P(_z);
// }
