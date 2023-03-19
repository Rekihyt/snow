const std = @import("std");
const os = std.os;
const fs = std.fs;
const panic = std.debug.panic;
const zgl = @import("zgl");
const Int = zgl.Int;
const Program = zgl.Program;
const Shader = zgl.Shader;
const ShaderType = zgl.ShaderType;
const dbg = std.debug.print;
const err = std.log.err;
const info = std.log.info;
const Allocator = std.Allocator;
const meta = std.meta;
const Float = zgl.Float;
const UniformMap = std.StringHashMap(u32);
const allocator = std.heap.page_allocator;

pub const ShaderDescription = struct {
    source: []const u8,
    shader_type: ShaderType,
};

// Based on https://github.com/fendevel/Guide-to-Modern-OpenGL-Functions#ideal-way-of-retrieving-all-uniform-names
// pub fn getUniforms(program: Program, allocator: Allocator) UniformMap {
//     var uniforms: UniformMap = UniformMap.init(allocator);
//     const len = zgl.getProgram(.UniformL)
//     for (meta.fields(Uniforms)) |field_type| {
//         if (zgl.getUniformLocation(program, uniform_names[i])) |loc|
//             uniforms[i] = switch (field_type) {
//                 i32 => zgl.uniform1i(loc, 0),
//                 else => error.UnknownUniformType,
//             }
//         else
//             error.UniformNotFound;
//     }
// }

pub fn create(
    descriptions: []const ShaderDescription,
) !Program {
    const program = zgl.createProgram();
    for (descriptions) |description| {
        var shader = try initGlShader(
            description.source,
            description.shader_type,
        );
        zgl.attachShader(
            program,
            shader,
        );
        // Mark for deletion for when program is deleted
        zgl.deleteShader(shader);
    }
    zgl.linkProgram(program);
    return program;
}

fn initGlShader(source: []const u8, shader_type: ShaderType) !Shader {
    const shader = zgl.createShader(shader_type);
    zgl.shaderSource(shader, 1, &.{source});
    zgl.compileShader(shader);

    // TODO: if debug
    {
        const info_log = try zgl.getShaderInfoLog(shader, allocator);
        defer allocator.free(info_log);
        if (info_log.len != 0)
            info("{s}", .{info_log});
    }

    return shader;
}
