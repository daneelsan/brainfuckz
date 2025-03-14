const std = @import("std");
const debug = std.debug;
const fs = std.fs;
const io = std.io;
const mem = std.mem;
const process = std.process;

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

    const allocator = arena.allocator();

    const args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    const stdout = io.getStdOut().writer();

    if (args.len <= 1) {
        try stdout.print("{s}", .{usage});
        process.exit(1);
    }

    const command = args[1];
    const commandArgs = args[2..];

    var brain = try Brain.init(allocator, Brain.defaultMemorySize);
    defer brain.deinit();

    if (mem.eql(u8, command, "help")) {
        try stdout.print("{s}", .{usage});
    } else if (mem.eql(u8, command, "code")) {
        if (commandArgs.len < 1) {
            debug.print("Error: Missing [CODE] argument.\n", .{});
            process.exit(1);
        }
        const code: []const u8 = commandArgs[0];

        // TODO: Implement optimize function
        // _ = brain.compile(code);
        _ = try brain.interpret(code, 0, false);
    } else if (mem.eql(u8, command, "file")) {
        if (commandArgs.len < 1) {
            debug.print("Error: Missing [PATH] argument.\n", .{});
            process.exit(1);
        }

        // TODO: Check .brain extension?
        const file = try fs.cwd().openFile(commandArgs[0], .{ .mode = .read_only });
        defer file.close();

        const code = try file.readToEndAlloc(allocator, maxBytesRead);
        defer allocator.free(code);

        // _ = brain.compile(code);
        _ = try brain.interpret(code, 0, false);
    } else if (mem.eql(u8, command, "test")) {
        const stdin = std.io.getStdIn().reader();

        while (true) {
            try stdout.print("brainfuckz> ", .{});
            const code = try stdin.readUntilDelimiterAlloc(allocator, '\n', maxBytesRead);
            defer allocator.free(code);
            // try stdout.print("{s}", .{code});
            _ = try brain.interpret(code, 0, false);
            try stdout.print("\n", .{});
        }
    } else {
        // TODO: Print unrecognized and exit
        debug.print("{any}", .{args});
    }
}
