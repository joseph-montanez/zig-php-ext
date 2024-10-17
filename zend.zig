const std = @import("std");

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

pub const types = @import("Zend/types.zig");
pub const args = @import("Zend/args.zig");
pub const compile = @import("Zend/compile.zig");
pub const string = @import("Zend/string.zig");
pub const api = @import("Zend/api.zig");
pub const hash = @import("Zend/hash.zig");

pub usingnamespace types;
pub usingnamespace args;
pub usingnamespace compile;
pub usingnamespace string;
pub usingnamespace api;
pub usingnamespace hash;

// const PhpAllocator = struct {
//     pub fn alloc(_: *PhpAllocator, len: usize) !*u8 {
//         const filename = "ext.zig"; // Set this to the current filename
//         const lineno: u32 = 25; // Set this to the current line number

//         const ptr = php._emalloc(len, filename, lineno, filename, lineno);
//         if (ptr == null) {
//             return error.OutOfMemory;
//         }
//         return @ptrCast(ptr);
//     }

//     pub fn free(_: *PhpAllocator, ptr: *u8) void {
//         const filename = "ext.zig"; // Set this to the current filename
//         const lineno: u32 = 36; // Set this to the current line number

//         php._efree(ptr, filename, lineno, filename, lineno);
//     }
// };

pub const ExecutorGlobalField = enum {
    UNINITIALIZED_ZVAL,
    ERROR_ZVAL,
    SYMBOL_TABLE,
    FUNCTION_TABLE,
    CLASS_TABLE,
    VM_STACK_TOP,
    VM_STACK_END,
    VM_STACK,
    VM_INTERRUPT,
};

pub fn EG(comptime field: ExecutorGlobalField) switch (field) {
    .UNINITIALIZED_ZVAL => *php.zval,
    .ERROR_ZVAL => *php.zval,
    .SYMBOL_TABLE => *[*c]php.zend_array,
    .FUNCTION_TABLE => *[*c]php.HashTable,
    .CLASS_TABLE => *[*c]php.HashTable,
    .VM_STACK_TOP => *[*c]php.zval,
    .VM_STACK_END => *[*c]php.zval,
    .VM_STACK => *php.zend_vm_stack,
    .VM_INTERRUPT => *php.zend_atomic_bool,
} {
    if (@hasDecl(config, "ZTS")) {
        const tsrm_ls = php.tsrm_get_ls_cache() orelse {
            @panic("Failed to get thread-safe resource manager cache.");
        };
        const tsrm_ls_base = @as([*]u8, @ptrCast(tsrm_ls));
        const executor_globals_offset = php.get_executor_globals_offset();
        const eg_ptr = @as(*php.zend_executor_globals, @ptrCast(@alignCast(tsrm_ls_base + executor_globals_offset)));
        return switch (field) {
            .UNINITIALIZED_ZVAL => &eg_ptr.uninitialized_zval,
            .ERROR_ZVAL => &eg_ptr.error_zval,
            .SYMBOL_TABLE => &eg_ptr.symbol_table,
            .FUNCTION_TABLE => &eg_ptr.function_table,
            .CLASS_TABLE => &eg_ptr.class_table,
            .VM_STACK_TOP => &eg_ptr.vm_stack_top,
            .VM_STACK_END => &eg_ptr.vm_stack_end,
            .VM_STACK => &eg_ptr.vm_stack,
            .VM_INTERRUPT => &eg_ptr.vm_interrupt,
        };
    } else {
        const executor_globals_ptr: *php.zend_executor_globals = php.get_executor_globals() orelse {
            @panic("Failed to get executor globals.");
        };
        return switch (field) {
            .UNINITIALIZED_ZVAL => &executor_globals_ptr.uninitialized_zval,
            .ERROR_ZVAL => &executor_globals_ptr.error_zval,
            .SYMBOL_TABLE => &executor_globals_ptr.symbol_table,
            .FUNCTION_TABLE => &executor_globals_ptr.function_table,
            .CLASS_TABLE => &executor_globals_ptr.class_table,
            .VM_STACK_TOP => &executor_globals_ptr.vm_stack_top,
            .VM_STACK_END => &executor_globals_ptr.vm_stack_end,
            .VM_STACK => &executor_globals_ptr.vm_stack,
            .VM_INTERRUPT => &executor_globals_ptr.vm_interrupt,
        };
    }
}

pub const ExecutorField = enum {
    OPLINE,
    CALL,
    RETURN_VALUE,
    FUNC,
    THIS,
    PREV_EXECUTE_DATA,
    SYMBOL_TABLE,
    RUN_TIME_CACHE,
    EXTRA_NAMED_PARAMS,
};

pub fn EX(comptime field: ExecutorField) switch (field) {
    .THIS => *php.zval,
    .FUNC => *[*c]php.zend_function,
    .OPLINE => *[*c]const php.zend_op,
    .CALL => *[*c]php.zend_execute_data,
    .EXTRA_NAMED_PARAMS => *[*c]php.zend_array,
    .PREV_EXECUTE_DATA => *[*c]php.zend_execute_data,
    .RETURN_VALUE => *[*c]php.zval,
    .RUN_TIME_CACHE => *[*c]?*anyopaque,
    .SYMBOL_TABLE => *[*c]php.zend_array,
} {
    const executor_data_ptr: *php.zend_execute_data = php.get_execute_data() orelse {
        @panic("Failed to get executor data.");
    };

    return switch (field) {
        .THIS => &executor_data_ptr.This,
        .FUNC => &executor_data_ptr.func,
        .OPLINE => &executor_data_ptr.opline,
        .CALL => &executor_data_ptr.call,
        .EXTRA_NAMED_PARAMS => &executor_data_ptr.extra_named_params,
        .PREV_EXECUTE_DATA => &executor_data_ptr.prev_execute_data,
        .RETURN_VALUE => &executor_data_ptr.return_value,
        .RUN_TIME_CACHE => &executor_data_ptr.run_time_cache,
        .SYMBOL_TABLE => &executor_data_ptr.symbol_table,
    };
}
