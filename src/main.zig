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

    const result = try sdl3.render.Renderer.initWithWindow("ZSR", SCREEN_W, SCREEN_H, .{});
    const window = result.window;
    const renderer = result.renderer;
    // const window = try sdl3.video.Window.init("ZSR", SCREEN_W, SCREEN_H, .{});
    defer window.deinit();
    defer renderer.deinit();

    const surface = try window.getSurface();
    try surface.fillRect(null, surface.mapRgb(0, 0, 0));
    try window.updateSurface();
    try renderer.setDrawColor(.{ .r = 200, .g = 100, .b = 51, .a = 255 });
    try renderer.renderPoint(sdl3.rect.FPoint{ .x = 500, .y = 250 });
    try renderer.present();

    while (true) {
        switch (try sdl3.events.waitAndPop()) {
            .quit => break,
            .terminating => break,
            else => {},
        }
    }
}
