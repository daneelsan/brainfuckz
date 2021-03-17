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
    \\
;

pub fn main() anyerror!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const stdout = std.io.getStdOut().writer();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len <= 1) {
        try stdout.print("{s}", .{usage});
        std.process.exit(1);
    }

    const command = args[1];
    const commandArgs = args[2..];

    if (mem.eql(u8, command, "help")) {
        try stdout.print("{s}", .{usage});
    } else if (mem.eql(u8, command, "code")) {
        const code: []const u8 = commandArgs[0];

        var brain = Brain{};
        _ = brain.compile(code);
        const steps = brain.interpret();
    } else if (mem.eql(u8, command, "file")) {
        const file = try fs.cwd().openFile(commandArgs[0], .{ .read = true });
        defer file.close();
        var code = try file.readToEndAlloc(allocator, maxBytesRead);

        var brain = Brain{};
        _ = brain.compile(code);
        const steps = brain.interpret();
    } else {
        std.debug.print("{any}", .{args});
    }

    // var brain = Brain{};
    // std.debug.print("{any}", .{brain.memory[0..10].*});
}
