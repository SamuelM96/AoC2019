const std = @import("std");

const Point = struct {
    x: f64,
    y: f64,
};

const Line = struct {
    const Self = @This();

    start: Point,
    end: Point,

    fn intersects(self: Self, other: Self) ?Point {
        const denom = self.denominator(other);
        if (denom == 0) return null;

        const ua = ((other.end.x - other.start.x) * (self.start.y - other.start.y) - (other.end.y - other.start.y) * (self.start.x - other.start.x)) / denom;
        if (ua < 0 or ua > 1) return null;

        const ub = ((self.end.x - self.start.x) * (self.start.y - other.start.y) - (self.end.y - self.start.y) * (self.start.x - other.start.x)) / denom;
        if (ub < 0 or ub > 1) return null;

        return .{
            .x = self.start.x + ua * (self.end.x - self.start.x),
            .y = self.start.y + ua * (self.end.y - self.start.y),
        };
    }

    inline fn denominator(self: Self, other: Self) f64 {
        return (other.end.y - other.start.y) * (self.end.x - self.start.x) - (other.end.x - other.start.x) * (self.end.y - self.start.y);
    }

    inline fn len(self: Self) f64 {
        // Relying on the fact that lines are only vertical or horizontal
        return @abs(self.start.x - self.end.x + self.start.y - self.end.y);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "day3.input", std.math.maxInt(usize));
    const trimmed = std.mem.trim(u8, input, " \n");

    var timer = try std.time.Timer.start();
    timer.reset();
    var result = try solvePart1(allocator, trimmed);
    var elapsed_ns = timer.read();
    var elapsed = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;
    std.debug.print("Part 1: {d:<3}  =>  {d:.6} seconds\n", .{ result, elapsed });

    timer.reset();
    result = try solvePart2(allocator, trimmed);
    elapsed_ns = timer.read();
    elapsed = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;
    std.debug.print("Part 2: {d:<3}  =>  {d:.6} seconds\n", .{ result, elapsed });
}

fn solvePart1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var it = std.mem.splitScalar(u8, input, '\n');

    const lines1 = try parseLine(allocator, it.next().?);
    const lines2 = try parseLine(allocator, it.next().?);

    var dist: usize = std.math.maxInt(usize);
    for (lines1.items) |l1| {
        for (lines2.items) |l2| {
            if (l1.intersects(l2)) |p| {
                if (std.math.approxEqAbs(f64, p.x, 0, std.math.floatEps(f64)) and std.math.approxEqAbs(f64, p.y, 0, std.math.floatEps(f64))) continue;
                dist = @min(dist, @as(usize, @intFromFloat(@abs(p.x + p.y))));
            }
        }
    }

    return dist;
}

fn solvePart2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var it = std.mem.splitScalar(u8, input, '\n');

    const lines1 = try parseLine(allocator, it.next().?);
    const lines2 = try parseLine(allocator, it.next().?);

    var steps: usize = std.math.maxInt(usize);
    var dist1: f64 = 0;
    var dist2: f64 = 0;
    for (lines1.items) |l1| {
        dist2 = 0;
        for (lines2.items) |l2| {
            if (l1.intersects(l2)) |p| {
                if (std.math.approxEqAbs(f64, p.x, 0, std.math.floatEps(f64)) and std.math.approxEqAbs(f64, p.y, 0, std.math.floatEps(f64))) continue;
                const a = Line{ .start = l1.start, .end = p };
                const b = Line{ .start = l2.start, .end = p };
                steps = @min(steps, @as(usize, @intFromFloat(dist1 + a.len() + dist2 + b.len())));
            }
            dist2 += l2.len();
        }
        dist1 += l1.len();
    }

    return steps;
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) !std.ArrayList(Line) {
    var lines = std.ArrayList(Line).init(allocator);
    var it = std.mem.splitScalar(u8, line, ',');
    var start = Point{ .x = 0, .y = 0 };
    while (it.next()) |op| {
        const dist = try std.fmt.parseFloat(f64, op[1..]);
        const end = switch (op[0]) {
            'U' => Point{ .x = start.x, .y = start.y + dist },
            'D' => Point{ .x = start.x, .y = start.y - dist },
            'L' => Point{ .x = start.x - dist, .y = start.y },
            'R' => Point{ .x = start.x + dist, .y = start.y },
            else => unreachable,
        };
        const l = Line{ .start = start, .end = end };
        try lines.append(l);
        start = end;
    }
    return lines;
}
