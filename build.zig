const std = @import("std");
const Build = std.Build;
const builtin = @import("builtin");
const glfw = @import("mach-glfw/build.zig");

pub fn build(b: *Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    var exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.install();

    exe.addAnonymousModule("zgl", .{ .source_file = .{ .path = "zgl/zgl.zig" } });
    exe.addAnonymousModule("zigimg", .{ .source_file = .{ .path = "zigimg/zigimg.zig" } });
    exe.addAnonymousModule("mach-glfw", .{ .source_file = .{ .path ="mach-glfw/src/main.zig" } });
    exe.addAnonymousModule("zalgebra", .{ .source_file = .{ .path =  "zalgebra/src/main.zig" } });

    exe.linkSystemLibrary("epoxy");

    try glfw.link(b, exe, .{});

    exe.install();

    const run = b.step("run", "Let it snow");
    const run_exe = exe.run();
    run_exe.step.dependOn(b.getInstallStep());
    run.dependOn(&run_exe.step);
}
