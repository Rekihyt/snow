const std = @import("std");
const zgl = @import("zgl");
const Float = zgl.Float;
const Buffer = zgl.Buffer;

/// A game object that has some kind of buffer, and a way to load and draw it.
/// Data is mutably borrowed.
/// TODO: currently `init` must be called again if `data` is resized
pub const BufferObject = struct {
    stride: usize,
    data: []Float,
    buffer: Buffer,
    buffer_target: zgl.BufferTarget,

    pub fn draw(self: BufferObject) void {
        // The number of primitives is the buffer length divided by the number
        // of vertices per primitive.

        zgl.drawArrays(.points, 0, self.data.len / self.stride);
    }

    /// Loads the current `data` into the gpu.
    pub fn load(
        self: *BufferObject,
    ) void {
        zgl.bindBuffer(self.buffer, self.buffer_target);
        zgl.bufferSubData(self.buffer_target, 0, Float, self.data);
    }

    /// Must 'record' this in a vao, otherwise the current vao will be used
    /// for calls to `draw`.
    pub fn create(
        data: []Float,
        stride: u32,
        buffer_target: zgl.BufferTarget,
    ) BufferObject {
        var self = BufferObject{
            .buffer = zgl.genBuffer(),
            .data = data,
            .stride = stride,
            .buffer_target = buffer_target,
        };

        zgl.bindBuffer(self.buffer, buffer_target);
        zgl.bufferData(buffer_target, Float, self.data, .dynamic_draw);

        zgl.vertexAttribPointer(
            0,
            stride,
            .float,
            false,
            stride * @sizeOf(Float),
            0,
        );
        zgl.enableVertexAttribArray(0);

        return self;
    }

    pub fn delete(self: BufferObject) void {
        zgl.deleteBuffer(self.buffer);
    }
};
