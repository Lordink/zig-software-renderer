const sdl3 = @import("sdl3");
const std = @import("std");

const SCREEN_W = 1280;
const SCREEN_H = 720;

// NOTE: Doesn't do window.updateSurface()
fn paintPix(surf: *const sdl3.surface.Surface, x: usize, y: usize, col: sdl3.pixels.Color) !void {
    try surf.writePixel(x, y, col);
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
    try paintPix(&surface, 300, 200, .{ .r = 250, .g = 200, .b = 34, .a = 255 });
    try window.updateSurface();

    while (true) {
        switch (try sdl3.events.waitAndPop()) {
            .quit => break,
            .terminating => break,
            else => {},
        }
    }
}
