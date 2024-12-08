const std = @import("std");

const DEBUG = true;

const Op = enum(u8) {
    add = 1,
    mul = 2,
    input = 3,
    output = 4,
    jump_if_true = 5,
    jump_if_false = 6,
    less_than = 7,
    equals = 8,
    halt = 99,
};

const Instruction = struct {
    const Self = @This();

    op: Op,
    modes: [3]bool,

    fn decode(instruction: usize) Self {
        return .{
            .op = @enumFromInt(instruction % 100),
            .modes = .{
                (instruction / 100) % 10 == 1,
                (instruction / 1000) % 10 == 1,
                (instruction / 10000) % 10 == 1,
            },
        };
    }
};

const Computer = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    memory: []isize,
    ip: usize,

    pub fn init(allocator: std.mem.Allocator, program: []const isize) !Self {
        return .{
            .ip = 0,
            .memory = try allocator.dupe(isize, program),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }

    inline fn getParam(self: *const Self, pos: usize, immediate: bool) isize {
        const value = self.memory[self.ip + pos];
        return if (immediate) value else self.memory[@as(usize, @intCast(value))];
    }

    pub fn execute(self: *Self) !isize {
        const stdin = std.io.getStdIn().reader();
        var buffer: [1024]u8 = undefined;

        var last_result: isize = 0;
        while (self.ip < self.memory.len) {
            const inst = Instruction.decode(@as(usize, @intCast(self.memory[self.ip])));
            if (inst.op == .halt) break;

            print("[{d:0>3}]  ", .{self.ip});

            switch (inst.op) {
                .add, .mul, .less_than, .equals => {
                    const a = self.getParam(1, inst.modes[0]);
                    const b = self.getParam(2, inst.modes[1]);
                    const dest = @as(usize, @intCast(self.memory[self.ip + 3]));
                    const result = switch (inst.op) {
                        .add => a + b,
                        .mul => a * b,
                        .less_than => @intFromBool(a < b),
                        .equals => @intFromBool(a == b),
                        else => unreachable,
                    };
                    print("{s}  {d}, {d}, [{d}] => {d}\n", .{ @tagName(inst.op), a, b, dest, result });
                    last_result = @intCast(dest);
                    self.memory[dest] = result;
                    self.ip += 4;
                },
                .input => {
                    const dest = @as(usize, @intCast(self.memory[self.ip + 1]));
                    print("in   [{d}] => ", .{dest});
                    const input = try stdin.readUntilDelimiterOrEof(&buffer, '\n') orelse return error.InvalidInput;
                    self.memory[dest] = try std.fmt.parseInt(isize, input, 10);
                    self.ip += 2;
                },
                .output => {
                    const value = self.getParam(1, inst.modes[0]);
                    print("out  => {d}\n", .{value});
                    last_result = value;
                    self.ip += 2;
                },
                .jump_if_true, .jump_if_false => {
                    const a = self.getParam(1, inst.modes[0]);
                    const b = self.getParam(2, inst.modes[1]);
                    const jump = switch (inst.op) {
                        .jump_if_true => a > 0,
                        .jump_if_false => a == 0,
                        else => unreachable,
                    };
                    print("{s}  {d}, {d} => {any}\n", .{ @tagName(inst.op), a, b, jump });
                    self.ip = if (jump) @intCast(b) else self.ip + 3;
                },
                else => unreachable,
            }
        }

        return last_result;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "day5.input", std.math.maxInt(usize));

    const data = try parse(allocator, input);
    defer data.deinit();

    var computer = try Computer.init(allocator, data.items);
    defer computer.deinit();

    _ = try computer.execute();
}

inline fn print(comptime fmt: []const u8, args: anytype) void {
    if (DEBUG) std.debug.print(fmt, args);
}

fn parse(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(isize) {
    var data = std.ArrayList(isize).init(allocator);
    var it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, input, " \n"), ',');
    while (it.next()) |token| {
        try data.append(try std.fmt.parseInt(isize, token, 10));
    }
    return data;
}
