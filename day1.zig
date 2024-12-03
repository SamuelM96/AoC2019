const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "day1.input", std.math.maxInt(usize));

    std.debug.print("Part 1: {d}\n", .{try solvePart1(input)});
    std.debug.print("Part 2: {d}\n", .{try solvePart2(input)});
}

pub fn solvePart1(input: []const u8) !usize {
    var sum: usize = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const mass = try std.fmt.parseInt(usize, token, 10);
        sum += (mass / 3) - 2;
    }
    return sum;
}

pub fn solvePart2(input: []const u8) !usize {
    var sum: usize = 0;
    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        var mass = try std.fmt.parseInt(usize, token, 10);
        while (mass > 0) {
            mass = std.math.sub(usize, mass/3, 2) catch break;
            sum += mass;
        }
    }
    return sum;
}
