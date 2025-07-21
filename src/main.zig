const sdl3 = @import("sdl3");
const std = @import("std");

const SCREEN_W = 1280;
const SCREEN_H = 720;

pub fn main() !void {
    defer sdl3.shutdown();
    // Init sdl3 window
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    const window = try sdl3.video.Window.init("ZSR", SCREEN_W, SCREEN_H, .{});
    defer window.deinit();

    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(120, 91, 191));
    try window.updateSurface();

    while (true) {
        switch (try sdl3.events.waitAndPop()) {
            .quit => break,
            .terminating => break,
            else => {},
        }
    }
}
