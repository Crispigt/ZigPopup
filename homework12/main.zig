const std = @import("std");
//const poly = @import("poly.zig");

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    
    var splitter = std.mem.splitAny(u8, data, " \n");

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    while (splitter.next()) |token| {
        if (std.mem.eql(u8,token, "") or std.mem.eql(u8,token, "0")) {
            continue;
        }

        const exp = splitter.next().?;

        const EXPLOSION = try findStringAndRemoveString(allocator, token, exp);

        if (EXPLOSION.len == 0) {
            try writer.print("FRULA \n", .{});
            break;
        } else{
            try writer.print("{s} \n", .{EXPLOSION});
            break;
        }
        
    }
    
    try buffered.flush();
}

fn findStringAndRemoveString(allocator: std.mem.Allocator, string: []const u8, t: []const u8) ![]u8 {
    if (t.len == 0) return allocator.dupe(u8, string);

    var newStringOld = std.ArrayList(u8).init(allocator);
    defer newStringOld.deinit();

    const expLen = t.len;

    for (string) |c| {
        try newStringOld.append(c);
        if (newStringOld.items.len >= expLen) {
            if (std.mem.eql(u8, newStringOld.items[newStringOld.items.len - expLen..newStringOld.items.len], t)) {
                newStringOld.shrinkRetainingCapacity(newStringOld.items.len - expLen);
            }
        }
    }

    return newStringOld.toOwnedSlice();
}


pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readAllAlloc(allocator, std.math.maxInt(usize));
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const page_alloc = std.heap.page_allocator;

    var arena = std.heap.ArenaAllocator.init(page_alloc);
    defer arena.deinit();
    const aa = arena.allocator();

    const all_data = try readInput(page_alloc, stdin);
    defer page_alloc.free(all_data);

    try parseAndRunCombinedArray(aa, all_data);
}

