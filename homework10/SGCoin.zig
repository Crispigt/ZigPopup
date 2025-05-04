// Author: Felix Stenberg

const std = @import("std");


pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readAllAlloc(allocator, std.math.maxInt(usize));
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const page_alloc = std.heap.page_allocator;

    // var arena = std.heap.ArenaAllocator.init(page_alloc);
    // defer arena.deinit();
    // const aa = arena.allocator();

    const all_data = try readInput(page_alloc, stdin);
    defer page_alloc.free(all_data);

    try parseAndRunCombinedArray( all_data);
}

fn parseAndRunCombinedArray(data: []u8) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    const trimmed = std.mem.trim(u8, data, " \n");
    const inputH = try std.fmt.parseInt(i64, trimmed, 10);

    const resA = solve(inputH);

    try writer.print("a {d}\n", .{resA});
    try writer.print("a 160000819\n", .{ });
    try buffered.flush();
}


/// H(string, number, string2) => new hash

fn solve(inputH: i64) i64 {
    const s = 'a';
    var v: i64 = inputH;
    const c: i64 = @intCast(s);
    v = @mod((v * 31 + c), 1000000007);
    if (v < 0) v += 1000000007;
    
    var token = @mod((990000000 - 7 * v), 1000000007);
    if (token < 0) token += 1000000007;

    return token;
}
