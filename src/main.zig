const std = @import("std");
const assert = std.debug.assert;
const fs = std.fs;
const os = std.os;
const fmt = std.fmt;
const math = std.math;
const dbg = std.debug.print;
const allocator = std.heap.page_allocator;
const time = std.time;
const DefaultPrng = std.rand.DefaultPrng;

const shaders = @import("shaders.zig");
const input = @import("input.zig");
const ShaderDescription = shaders.ShaderDescription;
const Uniforms = shaders.Uniforms;
const zgl = @import("zgl");
const zwl = @import("zwl");
const glfw = @import("mach-glfw");
const za = @import("zalgebra");
const zigimg = @import("zigimg");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;

const Window = glfw.Window;
const Key = glfw.Key;
const Action = glfw.Action;
const Mods = glfw.Mods;
const Float = zgl.Float;
const Program = zgl.Program;

const Image = zigimg.Image;

// const AllShaders = @import("all_shaders.zig").AllShaders;
// const StaticGeometry = @import("static_geometry.zig").StaticGeometry;
// const Flake = @import("flake.zig").Flake;
const Sprite = @import("sprite.zig").Sprite;
const BufferObject = @import("bufferObject.zig").BufferObject;
// const Lighting = @import("lighting.zig").Lighting;
// const Particle = @import("particle.zig").Particle;

// // const Spritesheet = @import("spritesheet.zig").Spritesheet;
const stride = 3;
const texture_count = 4;
const flakes_per_texture = 1024;
const movement_delta = 0.01;
// const flakes_per_texture = math.pow(u32, 2, 15);

fn framebufferCallback(window: Window, width: u32, height: u32) void {
    _ = window;
    zgl.viewport(0, 0, width, height);
}

fn handleInput(window: Window, model: *za.Vec3) bool {
    const result = input.keys.count() == 0;
    if (!result) {
        var key_iter = input.keys.iterator();
        while (key_iter.next()) |key|
            switch (key) {
                .a => model.data[0] += movement_delta,
                .d => model.data[0] -= movement_delta,
                .space => model.data[1] += movement_delta,
                .left_shift => model.data[1] -= movement_delta,
                .w => model.data[2] += movement_delta,
                .s => model.data[2] -= movement_delta,
                .escape => window.setShouldClose(true),
            };
        input.clear();
    }
    return result;
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?*const anyopaque {
    _ = p;
    return glfw.getProcAddress(proc);
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    const defaultSize = .{ .height = 640, .width = 480 };
    const window = Window.create(defaultSize.height, defaultSize.width, "Snow", null, null, .{
        .transparent_framebuffer = true,
        .maximized = true,
        .context_version_major = 4,
        .context_version_minor = 6,
        // .samples = 4,
        .opengl_forward_compat = true,
        // .opengl_debug_context = true,
        .opengl_profile = .opengl_core_profile,
    }) orelse {
        std.log.err("Failed to create window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    window.setKeyCallback(input.keyCallback);
    window.setFramebufferSizeCallback(framebufferCallback);
    glfw.makeContextCurrent(window);
    glfw.swapInterval(1); // vsync

    const proc: glfw.GLProc = undefined;
    try zgl.loadExtensions(proc, glGetProcAddress);

    var size = window.getFramebufferSize();
    zgl.viewport(0, 0, size.height, size.height);
    zgl.enable(.blend);
    zgl.disable(.multisample);
    // zgl.enable(.depth_test);
    zgl.blendFunc(.src_alpha, .one_minus_src_alpha);
    zgl.clearColor(0.0, 0.0, 0.0, 0.0);

    // Load and init texture shaders
    const texture_shaders = try shaders.create(&.{
        ShaderDescription{
            .source = @embedFile("shaders/texture.vert"),
            .shader_type = .vertex,
        },
        ShaderDescription{
            .source = @embedFile("shaders/texture.geom"),
            .shader_type = .geometry,
        },
        ShaderDescription{
            .source = @embedFile("shaders/texture.frag"),
            .shader_type = .fragment,
        },
    });
    defer texture_shaders.delete();
    texture_shaders.use();

    var prng = DefaultPrng.init(@intCast(u64, time.milliTimestamp()));
    const random = prng.random();

    var flakes: [texture_count]Sprite = try createFlakes(
        texture_count,
        "sprites",
        random,
    );
    defer for (&flakes) |*flake|
        flake.delete();

    // Uniforms
    const timeUniform = zgl.getUniformLocation(texture_shaders, "time");
    const deltaTUniform = zgl.getUniformLocation(texture_shaders, "delta_t");
    var initialTime = time.milliTimestamp();
    const projection = za.perspective(
        45.0,
        @intToFloat(f32, size.width) / @intToFloat(f32, size.height),
        0.1,
        100.0,
    );

    var view = za.lookAt(Vec3.new(0.0, 0.0, -2), Vec3.zero(), Vec3.up());
    var model = Vec3.new(0.0, 0.0, 0.0);
    var mvp = Mat4.mul(projection, view.mul(
        Mat4.fromTranslate(model),
    ));
    const mvpUniform = zgl.getUniformLocation(texture_shaders, "mvp");
    zgl.uniformMatrix4fv(mvpUniform, false, &.{mvp.data});
    // std.debug.print("{any}\n", .{mvp.mulByVec4(za.Vec4.new(0.0, 0.0, 0.0, 1.0))});
    // const rotationUniform = zgl.getUniformLocation(texture_shaders, "rotation");

    while (!window.shouldClose()) {
        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        const now = time.milliTimestamp();
        // zgl.uniformMatrix4fv(rotationUniform, false, &.{Mat4.fromRotation(
        //     0.01 * @intToFloat(f32, now - initialTime),
        //     Vec3.new(0.0, 0.0, 1.0),
        // ).data});
        zgl.uniform1i(timeUniform, @truncate(i32, now));
        zgl.uniform1i(deltaTUniform, @truncate(i32, now - initialTime));

        if (handleInput(window, &model)) {
            // Recreate model matrix if there was input
            mvp = Mat4.mul(projection, view.mul(Mat4.fromTranslate(model)));
            zgl.uniformMatrix4fv(mvpUniform, false, &.{mvp.data});
        }

        var i: i32 = 0;
        for (&flakes) |*flake| {
            zgl.uniform1i(zgl.getUniformLocation(texture_shaders, "flake"), i);
            flake.tick(random.float(Float));
            flake.load();
            flake.draw();
            i += 1;
        }

        window.swapBuffers();
        glfw.pollEvents();
    }
}

/// Caller frees each flake.
/// Creates a flake for each file in `path`, up to `count`.
fn createFlakes(
    comptime count: usize,
    path: []const u8,
    prng: std.rand.Random,
) ![count]Sprite {
    var flakes: [count]Sprite = undefined;
    var texture_paths = (try fs.cwd().openIterableDir(path, .{})).iterate();
    var i: u32 = 0;
    var enumBuff: [16]u8 = undefined;
    var pathBuff: [512]u8 = undefined;
    while (try texture_paths.next()) |texture_entry| : (i += 1) {
        // Only read files while there are still flakes left to create
        if (i == count)
            break;
        flakes[i] = try Sprite.create(
            allocator,
            try fmt.bufPrint(
                &pathBuff,
                "{s}/{s}",
                .{ path, texture_entry.name },
            ),
            std.meta.stringToEnum(
                zgl.TextureUnit,
                try fmt.bufPrint(&enumBuff, "texture_{}", .{i}),
            ).?,
            stride, // stride for xyz
            flakes_per_texture,
        );
    }
    if (i != count) {
        std.log.err(
            "not enough texture files (found {}) for required texture " ++
                "count of: {}, in directory: {s}",
            .{ i, count, path },
        );
        os.exit(1);
    }

    // std.log.debug("range: {}, {*}\n", .{ vertices.len, &vertices });
    // Randomize initial positions

    for (flakes) |flake| {
        for (flake.buffer) |*vertex| {
            // Map the range [0, 1) to [-1, 1)
            vertex.* = 2 * prng.float(Float) - 1;
        }
    }

    return flakes;
}

// TODO: report bug, while loop with comptime int var post increment is not a compile error, but of course doesn't increment
