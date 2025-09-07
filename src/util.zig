const sdl3 = @import("sdl3");
const std = @import("std");
const Color = sdl3.pixels.Color;
const print = std.debug.print;

pub const Vec3 = struct {
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

pub const Sphere = struct {
    const Self = @This();

    center: Vec3,
    radius: f32,
    col: Color,

    pub fn new(center: Vec3, radius: f32, color: Color) Self {
        return .{ .center = center, .radius = radius, .col = color };
    }
};

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

pub fn rayTraceSpheres(spheres: []const Sphere, ray_origin: Vec3, ray_dir: Vec3, t_min: f32, t_max: f32) !Color {
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
