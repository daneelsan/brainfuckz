const std = @import("std");
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const dprint = std.debug.print;

const MEM_SIZE = std.math.maxInt(u16);
const MAX_CODE_SIZE = std.math.maxInt(u12);

pub const Brain = struct {
    // allocator: *Allocator,

    mem: [MEM_SIZE]u8 = [_]u8{0} ** MEM_SIZE,
    dp: u16 = 0, // data_pointer
    code: [MAX_CODE_SIZE]u8 = [_]u8{0} ** MAX_CODE_SIZE,
    ip: u12 = 0, // instruction pointer
    input: u8 = 0,
    output: u8 = 0,

    const Self = @This();

    // pub fn init(allocator: *Allocator, mem_size: usize) !Self {
    //     return Self{
    //         .allocator = allocator,
    //     };
    // }

    pub fn reset(self: *Self) void {
        self.resetMemory();
        self.resetCode();
        self.dp = 0;
        self.ip = 0;
        self.input = 0;
        self.output = 0;
    }

    pub fn resetMemory(self: *Self) void {
        for (self.mem) |*m| {
            m.* = 0;
        }
    }

    pub fn resetCode(self: *Self) void {
        for (self.code) |*c| {
            c.* = 0;
        }
    }

    pub fn compile(self: *Self, source: []const u8) usize {
        self.resetCode();
        const slice = if (source.len > self.code.len) source[0..self.code.len] else source;

        var i: usize = 0;
        for (slice) |char| {
            switch (char) {
                '>', '<', '+', '-', '[', ']', ',', '.' => {
                    self.code[i] = char;
                    i += 1;
                },
                else => {},
            }
        }
        return i;
    }

    pub fn interpret(self: *Self) usize {
        var i: usize = 0;
        while (true) : (i += 1) {
            if (!self.interpretOnce()) break;
        }
        return i;
    }

    pub fn interpretN(self: *Self, n: usize) usize {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            if (!self.interpretOnce()) break;
        }
        return i;
    }

    pub fn interpretOnce(self: *Self) bool {
        if (self.ip >= self.code.len) return false;

        const instr: u8 = self.code[self.ip];
        return self.execute(instr);
    }

    fn execute(self: *Self, instr: u8) bool {
        switch (instr) {
            '>' => {
                self.dp +%= 1;
            },
            '<' => {
                self.dp -%= 1;
            },
            '+' => {
                self.mem[self.dp] +%= 1;
            },
            '-' => {
                self.mem[self.dp] -%= 1;
            },
            '[' => {
                // If value of current cell is zero, jump to matching square bracket
                if (self.mem[self.dp] == 0) {
                    var depth: usize = 1;
                    while (depth != 0) {
                        self.ip += 1;
                        if (self.ip == self.code.len) return false;

                        switch (self.code[self.ip]) {
                            '[' => depth += 1,
                            ']' => depth -= 1,
                            0 => return false,
                            else => {},
                        }
                    }
                }
            },
            ']' => {
                // If value of current cell is not zero, loop back to matching square bracket
                if (self.mem[self.dp] != 0) {
                    var depth: usize = 1;
                    while (depth != 0) {
                        self.ip -= 1;
                        if (self.ip == 0) return false;

                        switch (self.code[self.ip]) {
                            '[' => depth -= 1,
                            ']' => depth += 1,
                            0 => return false,
                            else => {},
                        }
                    }
                }
            },
            ',' => {
                const byte = stdin.readByte() catch return false;
                self.mem[self.dp] = byte;
            },
            '.' => {
                stdout.print("{c}", .{self.mem[self.dp]}) catch return false;
            },
            else => return false,
        }
        self.ip += 1;
        return true;
    }

    pub fn printState(self: Self) void {
        comptime const radius = 16;

        dprint("\n[\n", .{});

        dprint("  code:                ", .{});
        var i = if (self.ip < radius) 0 else self.ip - radius;
        while (i < self.ip + radius) : (i += 1) {
            if (i < 0) {
                i = -1;
            } else if (i > self.code.len) {
                break;
            } else if (i == self.ip) {
                dprint("({c})", .{self.code[i]});
            } else {
                dprint("{c}", .{self.code[i]});
            }
        }
        dprint("\n", .{});
        dprint("  instruction pointer: {d}\n", .{self.ip});

        dprint("  memory:              ", .{});
        var d = if (self.dp < radius) 0 else self.dp - radius;
        while (d < self.dp + radius) : (d += 1) {
            if (d < 0) {
                d = -1;
            } else if (d > self.mem.len) {
                break;
            } else if (d == self.dp) {
                dprint("({x:0>2})", .{self.mem[d]});
            } else {
                dprint("[{x:0>2}]", .{self.mem[d]});
            }
        }
        dprint("\n", .{});
        dprint("  data pointer:        {d}\n", .{self.dp});

        dprint("  input:               '{c}'\n", .{self.input});
        dprint("  output:              '{c}'\n", .{self.output});
        dprint("]\n", .{});
    }

    pub fn printCode(self: Self) void {
        dprint("Code: {s}\n", .{self.code});
    }
};
