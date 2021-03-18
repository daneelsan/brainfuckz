const std = @import("std");
const mem = std.mem;
const fs = std.fs;

const maxBytesRead = std.math.maxInt(u32);

const Brain = @import("brain.zig").Brain;

const usage =
    \\Usage: brain [command]
    \\
    \\ Commands:
    \\
    \\ code [BRAIN]     Give brainfuck code to execute
    \\ file [PATH]      Execute the code found in a .brain file
    \\ help             Print this help message and exit
    \\ test             Enters interactive mode
    \\
;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const stdout = std.io.getStdOut().writer();

    if (args.len <= 1) {
        try stdout.print("{s}", .{usage});
        std.process.exit(1);
    }

    const command = args[1];
    const commandArgs = args[2..];

    var brain = try Brain.init(allocator, Brain.defaultMemorySize);
    defer brain.deinit();

    if (mem.eql(u8, command, "help")) {

        try stdout.print("{s}", .{usage});

    } else if (mem.eql(u8, command, "code")) {

        const code: []const u8 = commandArgs[0];

        // _ = brain.compile(code);
        const steps = try brain.interpret(code, 0, false);

    } else if (mem.eql(u8, command, "file")) {

        const file = try fs.cwd().openFile(commandArgs[0], .{ .read = true });
        defer file.close();

        var code = try file.readToEndAlloc(allocator, maxBytesRead);
        defer allocator.free(code);

        // _ = brain.compile(code);
        const steps = try brain.interpret(code, 0, false);

    } else if (mem.eql(u8, command, "test")) {

        const stdin = std.io.getStdIn().reader();

        while (true) {
            try stdout.print("brainfuckz> ", .{});
            const code = try stdin.readUntilDelimiterAlloc(allocator, '\n', maxBytesRead);
            defer allocator.free(code);
            // try stdout.print("{s}", .{code});
            const steps = try brain.interpret(code, 0, false);
            try stdout.print("\n", .{});
        }

    } else {
        std.debug.print("{any}", .{args});
    }

    // var brain = Brain{};
    // std.debug.print("{any}", .{brain.memory[0..10].*});
}
