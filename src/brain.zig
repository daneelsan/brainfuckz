const std = @import("std");
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();
const dprint = std.debug.print;

pub const Brain = struct {
    allocator: Allocator,

    mem: []u8,
    dp: usize = 0, // data_pointer
    // code: []const u8,
    ip: usize = 0, // instruction pointer
    input: u8 = 0,
    output: u8 = 0,

    const Self = @This();
    pub const defaultMemorySize = 30000;

    pub fn init(allocator: Allocator, mem_size: usize) !Self {
        const mem = try allocator.alloc(u8, mem_size);
        var self = Self{
            .allocator = allocator,
            .mem = mem,
            // .code = &[_]u8{0},
        };
        self.clearMemory();
        return self;
    }

    pub fn initDefault(allocator: *Allocator) !Self {
        return try init(allocator, defaultMemorySize);
    }

    pub fn deinit(self: Self) void {
        self.allocator.free(self.mem);
    }

    pub fn reset(self: *Self) void {
        self.clearMemory();
        // self.resetCode();
        self.dp = 0;
        self.ip = 0;
        self.input = 0;
        self.output = 0;
    }

    pub fn clearMemory(self: *Self) void {
        for (self.mem) |*m| {
            m.* = 0;
        }
    }

    pub const BrainError = error{
        DataPointerOverflow,
        DataPointerUnderflow,
        DataPointerOutOfBounds,
        InstructionPointerOutOfBounds,
        LeftBracketUnmatched,
        RightBracketUnmatched,
        InputFailed,
        OutputFailed,
    };

    pub fn interpret(self: *Self, code: []const u8, n: usize, debug: bool) BrainError!usize {
        const res = self.run(code, n, debug) catch |err| self.errorHandler(code, err);
        return res;
    }

    pub fn run(self: *Self, code: []const u8, n: usize, debug: bool) BrainError!usize {
        if (self.ip < 0 or self.ip >= code.len) {
            return BrainError.InstructionPointerOutOfBounds;
        }
        if (self.dp < 0 or self.dp >= self.mem.len) {
            return BrainError.DataPointerOutOfBounds;
        }

        var i: usize = 0;
        const cond = (n == 0); // 0 means loop forever
        if (debug) {
            self.printState(code);
            while (cond or i < n) : (i += 1) {
                const offset = try self.execute(code);
                self.ip = @intCast(@as(isize, @intCast(self.ip)) + offset);
                self.printState(code);
                if (self.ip == code.len) break;
            }
        } else {
            while (cond or i < n) : (i += 1) {
                const offset = try self.execute(code);
                self.ip = @intCast(@as(isize, @intCast(self.ip)) + offset);
                if (self.ip == code.len) break;
            }
        }
        return i;
    }

    fn execute(self: *Self, code: []const u8) BrainError!isize {
        var offset: isize = 1;
        switch (code[self.ip]) {
            '>' => {
                if (self.dp == self.mem.len - 1) return BrainError.DataPointerOverflow;
                self.dp += 1;
            },
            '<' => {
                if (self.dp == 0) return BrainError.DataPointerUnderflow;
                self.dp -= 1;
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
                    var ip: usize = self.ip;

                    while (depth != 0) : (offset += 1) {
                        if (ip == code.len - 1) return BrainError.LeftBracketUnmatched;
                        ip += 1;

                        switch (code[ip]) {
                            '[' => depth += 1,
                            ']' => depth -= 1,
                            else => {},
                        }
                    }
                }
            },
            ']' => {
                // If value of current cell is not zero, loop back to matching square bracket
                if (self.mem[self.dp] != 0) {
                    var depth: usize = 1;
                    var ip: usize = self.ip;
                    while (depth != 0) : (offset -= 1) {
                        if (ip == 0) return BrainError.RightBracketUnmatched;
                        ip -= 1;

                        switch (code[ip]) {
                            '[' => depth -= 1,
                            ']' => depth += 1,
                            else => {},
                        }
                    }
                }
            },
            ',' => {
                // TODO: How to read without 'enter'?
                const byte = stdin.readByte() catch return BrainError.InputFailed;
                self.mem[self.dp] = byte;
            },
            '.' => {
                stdout.print("{c}", .{self.mem[self.dp]}) catch return BrainError.OutputFailed;
            },
            else => {}, // Ignore other characters
        }
        return offset;
    }

    fn errorHandler(self: Self, code: []const u8, err: BrainError) BrainError {
        dprint("Error [{any}] (code[{d}]: {c}, mem[{d}]: {x:0>2}, in: {c}, out: {c})", .{
            err,
            self.ip,
            code[self.ip],
            self.dp,
            self.mem[self.dp],
            self.input,
            self.output,
        });
        return err;
    }

    pub fn printState(self: Self, code: []const u8) void {
        const radius = 16;

        dprint("\n[\n", .{});

        dprint("  code:                ", .{});
        var i = if (self.ip < radius) 0 else self.ip - radius;
        while (i < self.ip + radius) : (i += 1) {
            if (i < 0) {
                i = -1;
            } else if (i > code.len) {
                break;
            } else if (i == self.ip) {
                dprint("({c})", .{code[i]});
            } else {
                dprint("{c}", .{code[i]});
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
};

// Optimizes the code `source` by removing all non-brainfuck characters.
// Stores the resulting array in `buffer`.
// pub fn brainCodeOptimize(buffer: []u8, source: []const u8) usize {
//     const slice = if (source.len > self.code.len) source[0..self.code.len] else source;

//     var i: usize = 0;
//     for (source) |char| {
//         switch (char) {
//             '>', '<', '+', '-', '[', ']', ',', '.' => {
//                 self.code[i] = char;
//                 i += 1;
//             },
//             else => {},
//         }
//     }
//     return i;
// }
