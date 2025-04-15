/// Author: Felix Stenberg
///
const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readAllAlloc(allocator, std.math.maxInt(usize));
}

pub fn solve(cache: *std.ArrayList(usize), t: usize) !usize 
{
    if(t % 2 == 1){
        return 0;
    }
    if (t/2 < cache.items.len) {
        return cache.items[t/2];
    } else {
        var n: usize = cache.items.len;
        var last = cache.items[n-1];
        var last2 = cache.items[n-2];
        var newlast: usize = 0;
        
        while (n <= t/2) : (n += 1) {
            newlast = 4*last - last2;
            try cache.append(newlast);
            last2 = last;
            last = newlast;
        }
        
        return newlast;
    }
}

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    var splitter = std.mem.splitAny(u8, data, " \n");

    var cache = std.ArrayList(usize).init(allocator);

    try cache.append(1); //f(0)
    try cache.append(3); //f(2)

    while (splitter.next()) |token| {
        if (std.mem.eql(u8,token, "")) {
            continue;
        }
        if (std.mem.eql(u8,token, "-1")) {
            break;
        }
        const inp = try std.fmt.parseInt(usize, token,10);
        const res = try solve(&cache, inp);
        try writer.print("{d}\n", .{res});
    }
    try buffered.flush();
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const allocator = std.heap.page_allocator;

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    // const startRead = try Instant.now();
    const all_data = try readInput(
        allocator,
        stdin,
    );
    defer allocator.free(all_data);

    try parseAndRunCombinedArray(aa,all_data);

    // std.debug.print("this is res: \n", .{});
    // try printResults(testing);

}