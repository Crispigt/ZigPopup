// Author: Felix Stenberg

const std = @import("std");


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


const Interval = struct { start: f32, end: f32};

fn lessIntervals(_: void, a: Interval, b: Interval) bool {
    return a.end < b.end;
}


fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    
    var splitter = std.mem.splitAny(u8, data, " \n");

    const n = try std.fmt.parseInt(usize, splitter.next().?, 10);

    const result = try allocator.alloc(i32, n);

    for (0..n) |r| {
        const n2 = try std.fmt.parseInt(usize, splitter.next().?, 10);
        var intervals = try allocator.alloc(Interval, n2);
        defer allocator.free(intervals);
        const d = try std.fmt.parseFloat(f32, splitter.next().?);
        
        for (0..n2) |i| {
            const x = try std.fmt.parseFloat(f32, splitter.next().?);
            const y = try std.fmt.parseFloat(f32, splitter.next().?);

            const dist0 = @sqrt(std.math.pow(f32, x, 2) + std.math.pow(f32, y, 2));
            if (dist0 <= d) continue;

            var angle = std.math.atan2(y, x);
            angle = @mod(angle, 2 * std.math.pi);
            if (angle < 0) angle += 2 * std.math.pi;
            // dist0 = 0??
            const allowedAng = std.math.asin(d / dist0);
            const start = angle - allowedAng;
            const end = angle + allowedAng;

            intervals[i] = .{
                .start = if (start < 0) start + 2 * std.math.pi else start,
                .end = if (end > 2 * std.math.pi) end - 2 * std.math.pi else end,
            };

        }

        std.mem.sort(Interval, intervals, {}, lessIntervals);

        var res: i32 = 0;
        var currEnd: f32 = 0.0;
        var i: usize = 0;

        while (i < intervals.len) {
            res += 1;
            currEnd = intervals[i].end;
            i+=1;
            while (i < intervals.len and intervals[i].start <= currEnd) : (i+=1) {}
        }
        result[r] = res;
    }

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    for (result) |value| {
        try writer.print("{d}\n", .{value});
    }
    try buffered.flush();
}
