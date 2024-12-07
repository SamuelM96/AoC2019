const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "day4.input", std.math.maxInt(usize));
    const trimmed = std.mem.trim(u8, input, " \n");

    var it = std.mem.tokenizeScalar(u8, trimmed, '-');
    const start = try std.fmt.parseInt(usize, it.next().?, 10);
    const end = try std.fmt.parseInt(usize, it.next().?, 10);

    var timer = try std.time.Timer.start();
    timer.reset();
    var result = try solvePart1(start, end);
    var elapsed_ns = timer.read();
    var elapsed = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;
    std.debug.print("Part 1: {d:<3}  =>  {d:.6} seconds\n", .{ result, elapsed });

    timer.reset();
    result = try solvePart2(start, end);
    elapsed_ns = timer.read();
    elapsed = @as(f64, @floatFromInt(elapsed_ns)) / std.time.ns_per_s;
    std.debug.print("Part 2: {d:<3}  =>  {d:.6} seconds\n", .{ result, elapsed });
}

fn solvePart1(start: usize, end: usize) !usize {
    var count: usize = 0;
    var buffer = [6]u8{ 0, 0, 0, 0, 0, 0 };
    outer: for (start..end) |i| {
        const str = std.fmt.bufPrintIntToSlice(&buffer, i, 10, .upper, .{});
        var has_adjacent = false;
        for (1..str.len) |j| {
            if (str[j] < str[j - 1]) continue :outer;
            has_adjacent = has_adjacent or str[j] == str[j - 1];
        }
        if (!has_adjacent) continue;
        count += 1;
    }

    return count;
}

fn solvePart2(start: usize, end: usize) !usize {
    var total: usize = 0;
    var buffer = [6]u8{ 0, 0, 0, 0, 0, 0 };
    outer: for (start..end) |num| {
        const str = std.fmt.bufPrintIntToSlice(&buffer, num, 10, .upper, .{});
        var repeated = [9]u8{ 1, 1, 1, 1, 1, 1, 1, 1, 1 };
        for (1..str.len) |i| {
            if (str[i] < str[i - 1]) continue :outer;
            if (str[i] == str[i - 1]) repeated[str[i] - '0' - 1] += 1;
        }
        total += @intFromBool(std.mem.indexOfScalar(u8, &repeated, 2) != null);
    }

    return total;
}
