const std = @import("std");

const DEBUG = false;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "day2.input", std.math.maxInt(usize));

    const data = try parse(allocator, input);
    defer data.deinit();

    var stdout = std.io.getStdOut().writer();
    try stdout.print("Part 1: {d}\n", .{try execute(allocator, data.items, 12, 2)});

    for (0..100) |noun| {
        for (0..100) |verb| {
            const result = try execute(allocator, data.items, noun, verb);
            if (result == 19690720) {
                try stdout.print("Part 2: noun={d}, verb={d} => {d}\n", .{noun, verb, 100*noun+verb});
            }
        }
    }
}

inline fn print(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG) std.debug.print(fmt, args);
}

fn parse(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(usize) {
    var data = std.ArrayList(usize).init(allocator);
    var it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, input, " \n"), ',');
    while (it.next()) |token| {
        try data.append(try std.fmt.parseInt(usize, token, 10));
    }
    return data;
}

pub fn execute(allocator: std.mem.Allocator, program: []const usize, noun: usize, verb: usize) !usize {
    var data = try allocator.dupe(usize, program);
    defer allocator.free(data);

    data[1] = noun;
    data[2] = verb;

    var ip: usize = 0;
    var dest: usize = 0;
    while (ip < data.len) : (ip += 4) {
        const op = data[ip];
        if (op == 99) break;

        var a = data[ip+1];
        var b = data[ip+2];
        dest = data[ip+3];
        print("[{d:0>3}] {d:0>3} {d:0>3} {d:0>3} {d:0>3}  =>  ", .{ip, op, a, b, dest});
        a = data[a];
        b = data[b];
        switch (data[ip]) {
            1 => {
                print("add  {d}, {d}, [{d}] => {d}\n", .{a,b,dest, a+b});
                data[dest] = a+b;
            },
            2 => {
                print("mul  {d}, {d}, [{d}] => {d}\n", .{a,b,dest, a*b});
                data[dest] = a*b;
            },
            else => unreachable,
        }
    }

    for (data) |value| {
        print("{d},", .{value});
    }
    print("\n", .{});

    return data[dest];
}
