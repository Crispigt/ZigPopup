/// Author: Felix Stenberg
///
const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}

pub fn printResults(res: bool) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();
    if (res) {
        try writer.print("yes\n", .{});
    } else {
        try writer.print("no\n", .{});
    }

    try buffered.flush();
}

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const n = splitter.next().?;
    const count = try std.fmt.parseInt(usize, splitter.next().?, 10);


    const realNum = try makeF64(allocator,n, count);

    std.debug.print("realnum: {d}\n", .{realNum});


    // std.debug.print("res: {d}\n", .{res});

    std.debug.print("n:{s}\n", .{n});
}

fn makeF64(allocator: std.mem.Allocator,n: []const u8, count: usize) !f64 {
    var res = std.ArrayList(u8).init(allocator);
    defer res.deinit();
    try res.appendSlice(n);
    const repeat = n[n.len-count..];
    std.debug.print("repeat: {s}\n", .{repeat});
    while (res.items.len + repeat.len < 16) {
        try res.appendSlice(repeat);
    }
    const resOwned = try res.toOwnedSlice();
    std.debug.print("{s}\n", .{resOwned});
    defer allocator.free(resOwned);
    const resAsFloat: f64 = try std.fmt.parseFloat(f64, resOwned); 
    return resAsFloat;
}

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const allocator = std.heap.page_allocator;
    var buffer: [1024 * 1024]u8 = undefined;

    // const startRead = try Instant.now();
    const all_data = try readInput(
        allocator,
        stdin,
    );
    defer allocator.free(all_data);

    try parseAndRunCombinedArray(allocator, all_data);

    // std.debug.print("this is res: \n", .{});
    // try printResults(testing);

    buffer[1] = '1';
}