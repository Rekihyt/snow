const Builder = @import("std").build.Builder;
const builtin = @import("builtin");
const glfw = @import("mach-glfw/build.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    var exe = b.addExecutable("main", "src/main.zig");
    exe.setBuildMode(mode);

    const ziglibs = "./";
    exe.addPackagePath("zgl", ziglibs ++ "zgl/zgl.zig");
    exe.addPackagePath("zigimg", ziglibs ++ "zigimg/zigimg.zig");
    exe.addPackagePath("glfw", ziglibs ++ "mach-glfw/src/main.zig");
    exe.addPackagePath("zalgebra", ziglibs ++ "zalgebra/src/main.zig");

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
