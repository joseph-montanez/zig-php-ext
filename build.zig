const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const enable_zts = b.option(bool, "zts", "Enable Zend Thread Safety") orelse false;

    // // Conditionally set SDK_PATH only if on macOS
    // const SDK_PATH = if (target.result.os.tag.isDarwin())
    //     getSDKPath(b)
    // else
    //     b.option([]const u8, "sdk-path", "Path to the SDK") orelse "";

    // const PHP_SDK = if (enable_zts)
    //     "./build/php-8.3.12-zts-debug/bin/"
    // else
    //     "./build/php-8.3.12-non-zts-debug/bin/";

    // // Get the PHP include paths
    // const include_paths = getPHPIncludePaths(b, PHP_SDK);

    // // Run phpize to prepare the build
    // runPhpize(b, PHP_SDK);

    // const wrapper_c = b.addObject(.{
    //     .name = "wrapper",
    //     .target = target,
    //     .optimize = optimize,
    // });
    // wrapper_c.addCSourceFile(.{
    //     .file = .{ .cwd_relative = "wrapper.c" },
    //     .flags = &.{
    //         "-fPIC",
    //         b.fmt("-I{s}", .{SDK_PATH}),
    //         include_paths,
    //     },
    // });

    // const lib = b.addSharedLibrary(.{
    //     .name = "ext",
    //     .target = target,
    //     .optimize = optimize,
    // });

    // lib.addCSourceFile(.{ .file = .{ .cwd_relative = "ext.zig" }, .flags = &.{} });
    // lib.linkLibC();
    // lib.addObject(wrapper_c);
    // lib.addIncludePath(.{ .cwd_relative = "." });
    // lib.addIncludePath(.{ .cwd_relative = SDK_PATH });
    // lib.addIncludePath(.{ .cwd_relative = include_paths });

    // b.installArtifact(lib);

    const libExt = b.addSharedLibrary(.{
        .name = "ext",
        .root_source_file = b.path("ext.zig"),
        .target = target,
        .optimize = optimize,
        .version = .{ .major = 1, .minor = 2, .patch = 3 },
    });
    libExt.linkLibC();
    if (enable_zts) {
        libExt.addIncludePath(.{ .cwd_relative = "." });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-zts-debug/include/php" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-zts-debug/include/php/main" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-zts-debug/include/php/TSRM" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-zts-debug/include/php/Zend" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-zts-debug/include/php/ext" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-zts-debug/include/php/ext/date/lib" });
    } else {
        libExt.addIncludePath(.{ .cwd_relative = "." });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-non-zts-debug/include/php" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-non-zts-debug/include/php/main" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-non-zts-debug/include/php/TSRM" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-non-zts-debug/include/php/Zend" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-non-zts-debug/include/php/ext" });
        libExt.addIncludePath(.{ .cwd_relative = "build/php-8.3-non-zts-debug/include/php/ext/date/lib" });
    }

    b.installArtifact(libExt);
}

// fn getSDKPath(b: *std.Build) []const u8 {
//     const cmd = b.addSystemCommand(&.{ "xcrun", "--sdk", "macosx", "--show-sdk-path" });
//     const sdk_path = cmd.captureStdOut();

//     return switch (sdk_path) {
//         .cwd_relative => sdk_path.cwd_relative,
//         .generated => |gen| gen.path,
//         .dependency, .src_path => @panic("Unexpected LazyPath type"),
//     };
// }

// fn getPHPIncludePaths(b: *std.Build, php_sdk: []const u8) []const u8 {
//     const php_config = b.pathJoin(&.{ php_sdk, "php-config" });
//     const cmd = b.addSystemCommand(&.{ php_config, "--includes" });
//     const include_paths = cmd.captureStdOut();

//     return switch (include_paths) {
//         .cwd_relative => include_paths.cwd_relative,
//         .generated => |gen| gen.path,
//         .dependency, .src_path => @panic("Unexpected LazyPath type"),
//     };
// }

// fn runPhpize(b: *std.Build, php_sdk: []const u8) void {
//     const phpize = b.pathJoin(&.{ php_sdk, "phpize" });
//     _ = b.addSystemCommand(&.{phpize});
// }
