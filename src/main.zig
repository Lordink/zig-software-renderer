const sdl3 = @import("sdl3");
const std = @import("std");
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
const Vec3 = struct {
    const Self = @This();

    x: f32,
    y: f32,
    z: f32,

    // Dot product with another vec3
    pub fn dot(self: *const Self, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
    // subtract other vec from self
    pub fn sub(self: *const Self, other: Vec3) Vec3 {
        return .{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }
    pub fn new(x: f32, y: f32, z: f32) Self {
        return .{
            .x = x,
            .y = y,
            .z = z,
        };
    }
};

const Sphere = struct {
    const Self = @This();

    center: Vec3,
    radius: f32,
    col: Color,

    pub fn new(center: Vec3, radius: f32, color: Color) Self {
        return .{ .center = center, .radius = radius, .col = color };
    }
};

fn rayTraceSpheres(spheres: []const Sphere, ray_origin: Vec3, ray_dir: Vec3, t_min: f32, t_max: f32) !Color {
    var closest_t = std.math.floatMax(f32);
    var closest_sphere: ?*const Sphere = null;

    for (spheres) |*sphere| {
        const t1, const t2 = raySphereIntersect(ray_origin, ray_dir, sphere) catch {
            continue;
        };

        if (t1 >= t_min and t1 <= t_max and t1 < closest_t) {
            closest_t = t1;
            closest_sphere = sphere;
        }
        if (t2 >= t_min and t2 <= t_max and t2 < closest_t) {
            closest_t = t2;
            closest_sphere = sphere;
        }
    }

    if (closest_sphere) |sphere| {
        return sphere.col;
    } else {
        return error.NoHits;
    }
}

fn raySphereIntersect(ray_origin: Vec3, ray_dir: Vec3, sphere: *const Sphere) !struct { f32, f32 } {
    const r = sphere.radius;
    const co = ray_origin.sub(sphere.center);

    const a = ray_dir.dot(ray_dir);
    const b = 2.0 * co.dot(ray_dir);
    const c = co.dot(co) - r * r;

    const discr = b * b - 4 * a * c;
    if (discr < 0) {
        return error.NoIntersections;
    }
    const discr_sqrt = std.math.sqrt(discr);
    const t1 = (-b + discr_sqrt) / (2.0 * a);
    const t2 = (-b - discr_sqrt) / (2.0 * a);

    return .{ t1, t2 };
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
            Vec3.new(0, -1.0, 3.0),
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

test "raySphereIntersect" {
    const expect = std.testing.expect;

    const sphere = Sphere.new(
        Vec3.new(2.0, 0.0, 0.5),
        1.0,
        .{ .a = 255, .r = 255, .g = 255, .b = 255 },
    );
    const result = try raySphereIntersect(Vec3.new(0.0, 0.0, 0.0), Vec3.new(1.0, 0.0, 0.0), &sphere);

    print("Result: {}", .{result});
    try expect(result.@"0" > 0.0);
    try expect(result.@"1" > 0.0);
}
