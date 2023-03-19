const std = @import("std");
const zgl = @import("zgl");
const zigimg = @import("zigimg");
// const AllShaders = @import("all_shaders.zig").AllShaders;
const c = @import("c.zig");
const ShaderProgram = @import("shaders.zig").ShaderProgram;
const BufferObject = @import("bufferObject.zig").BufferObject;
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;

const dbg = std.debug.print;

const Texture = zgl.Texture;
const TextureUnit = zgl.TextureUnit;
const Image = zigimg.Image;
const VertexArray = zgl.VertexArray;
const Float = zgl.Float;
const UInt = zgl.UInt;
const Program = zgl.Program;
const info = std.log.info;
const Allocator = std.mem.Allocator;

/// A `Body` with a `Texture`
pub const Sprite = struct {
    allocator: Allocator,

    width: usize,
    height: usize,
    pixels: usize,

    buffer: []Float,
    vbo: BufferObject,

    texture: Texture,
    texture_unit: TextureUnit,
    vao: VertexArray,

    /// Draw the sprite's texture using `shader`.
    pub fn draw(self: *Sprite) void {
        zgl.bindVertexArray(self.vao);
        // Draw each collection of vertices
        self.vbo.draw();
    }

    pub fn tick(self: *Sprite, wind: Float) void {
        var i: usize = 0;

        while (i < self.vbo.data.len) : (i += self.vbo.stride) {
            // TODO: maybe make this a ptrCast?
            // var position = @ptrCast(*Vec3, positions[i .. i + dimensions]);

            // var position = Vec3.fromSlice(positions[i .. i + dimensions]);
            // position = position.add(Vec3.down().scale(0.001));
            // if (position.y() < -1) position.data[1] = 1;
            // std.mem.copy(f32, positions[i .. i + dimensions], &position.toArray());

            self.vbo.data[i + 0] += 0.0001 * wind;
            self.vbo.data[i + 1] -= 0.001;
            // TODO: this and future checks like it don't need to happen each frame
            if (self.vbo.data[i + 0] > 1) self.vbo.data[i + 0] = -1;
            if (self.vbo.data[i + 1] < -1) self.vbo.data[i + 1] = 1;
        }
    }

    /// Loads the current `vbo` into the gpu.
    pub fn load(self: *Sprite) void {
        self.vbo.load();
    }

    /// Loads this sprite into opengl buffers.
    /// Sets the vbo to vertices, and loads them accordingly.
    /// Load state is saved in vao for easy binding inside draw().
    pub fn create(
        allocator: Allocator,
        image_path: []const u8,
        texture_unit: TextureUnit,
        stride: u32,
        copies: u32,
    ) !Sprite {
        var self: Sprite = undefined;
        self.allocator = allocator;

        self.vao = zgl.genVertexArray();
        zgl.bindVertexArray(self.vao);

        try self.createTexture(texture_unit);
        try self.loadZigImage(image_path);

        zgl.generateMipmap(.@"2d");

        self.buffer = try self.allocator.alloc(Float, copies * stride);
        self.vbo = BufferObject.create(
            self.buffer,
            stride,
            .array_buffer,
        );

        return self;
    }

    pub fn delete(self: *Sprite) void {
        zgl.deleteVertexArray(self.vao);
        zgl.deleteTexture(self.texture);
        // Destroy buffers on opengl side
        self.vbo.delete();
        // Free buffers on our side
        self.allocator.free(self.buffer);
    }

    /// Generates the gl texture object and configures it
    fn createTexture(self: *Sprite, texture_unit: TextureUnit) !void {
        self.texture = zgl.createTexture(.@"2d");
        errdefer zgl.deleteTexture(self.texture);
        self.texture_unit = texture_unit;
        self.bindTexture();

        zgl.texParameter(.@"2d", .mag_filter, .linear);
        zgl.texParameter(.@"2d", .min_filter, .linear_mipmap_linear);
        zgl.texParameter(.@"2d", .wrap_s, .clamp_to_border);
        zgl.texParameter(.@"2d", .wrap_t, .clamp_to_border);
        zgl.pixelStore(.pack_alignment, 4);
    }

    /// Loads a png image into opengl.
    fn loadZigImage(self: *Sprite, image_path: []const u8) !void {
        // The image file, only needed to load into opengl
        var image = try Image.fromFilePath(self.allocator, image_path);
        defer image.deinit();
        self.pixels = image.pixels.len();
        self.width = image.width;
        self.height = image.height;

        // Create image for 4 * the number of pixels (for RGBA)
        const image_data = try self.allocator.alloc(u8, self.pixels * 4);
        defer self.allocator.free(image_data);

        // Conversion into opengl
        var image_iter = image.iterator();
        var i: u64 = 0;
        while (image_iter.next()) |pixel| : (i += 4) {
            const color = pixel.toRgba(u8);
            image_data[i + 0] = color.r;
            image_data[i + 1] = color.g;
            image_data[i + 2] = color.b;
            image_data[i + 3] = color.a;
        }
        zgl.textureImage2D(
            .@"2d",
            0,
            .rgba, // TODO: Should be rgba8
            image.width,
            image.height,
            .rgba,
            .unsigned_byte,
            @ptrCast([*]const u8, image_data),
        );
    }

    fn bindTexture(self: *Sprite) void {
        zgl.activeTexture(self.texture_unit);
        zgl.bindTexture(self.texture, .@"2d");
    }

    fn loadStbImage(self: *Sprite, image_path: [:0]const u8) !void {
        var nrChannels: c_int = undefined;
        const data = c.stbi_loadf(
            image_path,
            @ptrCast([*c]c_int, &self.width),
            @ptrCast([*c]c_int, &self.height),
            &nrChannels,
            0,
        );
        defer c.stbi_image_free(data);
        if (data != null) {
            info("Loaded texture", .{});
            zgl.textureImage2D(
                .@"2d",
                4,
                0,
                .rgb,
                self.width,
                self.height,
                .rgb,
                .unsigned_byte,
                @ptrCast([*]const u8, data),
            );
        } else @panic("Failed to load texture");
    }
};
