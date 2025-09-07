const sdl3 = @import("sdl3");
const std = @import("std");
const util = @import("util.zig");

const Vec3 = util.Vec3;
const Sphere = util.Sphere;
const rayTraceSpheres = util.rayTraceSpheres;

const Color = sdl3.pixels.Color;
const print = std.debug.print;

const SCREEN_W = 1280;
const SCREEN_H = 720;

const ASPECT_RATIO: f32 = @as(f32, @floatFromInt(SCREEN_W)) / @as(f32, @floatFromInt(SCREEN_H));

// Whole viewport is just (1 * aspect_ratio)x1, for simplicity
// World units
const VIEWPORT_W = 1.0 * ASPECT_RATIO;
const VIEWPORT_H = 1.0;
// Distance from the camera to the viewport
// World units
const VIEWPORT_D = 1.0;

// BG color
const DEFAULT_COLOR: Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };

const Canvas = struct {
    pub const width: i32 = SCREEN_W;
    pub const height: i32 = SCREEN_H;
    pub fn toViewport(x: i32, y: i32) Vec3 {
        return .{
            .x = @as(f32, @floatFromInt(x)) * VIEWPORT_W / @as(f32, width),
            .y = @as(f32, @floatFromInt(y)) * VIEWPORT_H / @as(f32, height),
            .z = VIEWPORT_D,
        };
    }
};

// NOTE: Doesn't do window.updateSurface()
// x and y are in Canvas Space
fn paintPix(surf: *const sdl3.surface.Surface, x: i32, y: i32, col: sdl3.pixels.Color) !void {
    // Canvas to screen (SDL) coords
    // Convert from center-is-at-0 to center-is-at-half-measure
    const s_x = x + SCREEN_W / 2;
    const s_y = SCREEN_H - (y + SCREEN_H / 2);

    // may be off-screen
    if (s_y < 0 or s_y >= SCREEN_H) {
        return;
    }
    //print("{}\n", .{s_y});
    try surf.writePixel(@intCast(s_x), @intCast(s_y), col);
}

pub fn main() !void {
    defer sdl3.shutdown();
    // Init sdl3 window
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    const window = try sdl3.video.Window.init("ZSR", SCREEN_W, SCREEN_H, .{});
    defer window.deinit();

    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(0, 0, 0));
    //try paintPix(&surface, 300, 200, .{ .r = 250, .g = 200, .b = 34, .a = 255 });
    try window.updateSurface();

    const spheres = [_]Sphere{
        Sphere.new(
            Vec3.new(0.0, -1.0, 3.0),
            1.0,
            .{ .r = 255, .g = 0, .b = 0, .a = 255 },
        ),
        Sphere.new(
            Vec3.new(2.0, 0.0, 4.0),
            1.0,
            .{ .r = 0, .g = 0, .b = 255, .a = 255 },
        ),
        Sphere.new(
            Vec3.new(-2.0, 0.0, 4.0),
            1.0,
            .{ .r = 0, .g = 255, .b = 0, .a = 255 },
        ),
    };

    while (true) {
        const o = Vec3.new(0, 0, 0);
        var x: i32 = -Canvas.width / 2;
        while (x < Canvas.width / 2) {
            var y: i32 = -Canvas.height / 2;
            while (y < Canvas.height / 2) {
                const ray_dir = Canvas.toViewport(x, y);
                const color = rayTraceSpheres(&spheres, o, ray_dir, 1.0, std.math.floatMax(f32)) catch DEFAULT_COLOR;
                try paintPix(&surface, x, y, color);
                y += 1;
            }
            x += 1;
        }
        try window.updateSurface();
        switch (try sdl3.events.waitAndPop()) {
            .quit => break,
            .terminating => break,
            else => {},
        }
    }
}
