const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const glfw = @import("mach-glfw/build.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.install();

    const ziglibs = "./";
    exe.addAnonymousModule(ziglibs ++ "zgl/zgl.zig", .{});
    exe.addAnonymousModule(ziglibs ++ "zigimg/zigimg.zig", .{});
    exe.addAnonymousModule(ziglibs ++ "mach-glfw/src/main.zig", .{});
    exe.addAnonymousModule(ziglibs ++ "zalgebra/src/main.zig", .{});

    // exe.addIncludeDir("stb_image-2.22");
    // exe.addCSourceFile("stb_image-2.22/stb_image_impl.c", &[_][]const u8{"-std=c99"});
    // exe.linkLibC();
    exe.linkSystemLibrary("epoxy");

    glfw.link(b, exe, .{});

    exe.install();

    const run = b.step("run", "Let it snow");
    const run_exe = exe.run();
    run_exe.step.dependOn(b.getInstallStep());
    run.dependOn(&run_exe.step);
}
