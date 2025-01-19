const std = @import("std");
const read = @import("./stdInput.zig");
const cardTrick = @import("./HW1/cardTrick.zig");
// const time = std.time;
// const Instant = time.Instant;
// const Timer = time.Timer;

pub fn main() !void {

    const stdin = std.io.getStdIn();

    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;

    const input = try read.readFullInputArrays(allocator, stdin.reader(), buffer[0..]);

    // for (input.items) |s| {
    //     for (s) |c| {
    //         std.debug.print("{c}", .{c});
    //     }
    //     std.debug.print("\n", .{});
    // }

    const intArray = try read.delimiterStringToInt(input, " ", allocator);

    // const start = try Instant.now();
    
    const res = try cardTrick.sovle(intArray, allocator);
    try cardTrick.printResult(res);

    // const end = try Instant.now();

    // const elapsed1: f64 = @floatFromInt(end.since(start));
    // std.debug.print("Time elapsed is: {d:.3}ms\n", .{
    //     elapsed1 / time.ns_per_ms,
    // });





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
    for (intArray.items) |value| {
        allocator.free(value);
    }
    intArray.deinit();
}