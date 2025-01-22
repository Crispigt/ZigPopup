const std = @import("std");
const read = @import("./stdInput.zig");
const help = @import("./HW1/help.zig");
// const time = std.time;
// const Instant = time.Instant;
// const Timer = time.Timer;

pub fn main() !void {

    const stdin = std.io.getStdIn();

    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;

    const input = try read.readFullInputArrays(allocator, stdin.reader(), buffer[0..]);

    const tes= try help.solveAll(input, allocator);

    try help.printRes(tes);

    buffer[1] = '1';

    // for (intArray.items) |s| {
    //     for (s) |d| {
    //         std.debug.print("{d} ", .{d});
    //     }
    //     std.debug.print("\n", .{});
    // }

    for (input.items) |value| {
        allocator.free(value);
    }
    input.deinit();
}