const std = @import("std");
const glfw = @import("mach-glfw");
// const IntegerBitSet = std.bit_set.IntegerBitSet;
const EnumSet = std.EnumSet;

pub var keys: EnumSet(Key) = .{};

const Key = enum { w, a, s, d, left_shift, space, escape };

pub fn clear() void {
    keys = .{};
}

pub fn keyCallback(
    window: glfw.Window,
    key: glfw.Key,
    scancode: i32,
    action: glfw.Action,
    mods: glfw.Mods,
) void {
    _ = window;
    _ = scancode;
    _ = mods;
    if (action == glfw.Action.release)
        return;

    if (std.meta.stringToEnum(Key, @tagName(key))) |valid_key|
        keys.insert(valid_key);
}
