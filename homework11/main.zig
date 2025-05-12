const std = @import("std");
const poly = @import("poly.zig");

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    
    var splitter = std.mem.splitAny(u8, data, " \n");

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    while (splitter.next()) |token| {
        if (std.mem.eql(u8,token, "") or std.mem.eql(u8,token, "0")) {
            continue;
        }

        const n = try std.fmt.parseInt(usize, token, 10);
        for (0..n) |_| {
            const n2 = try std.fmt.parseInt(usize, splitter.next().?, 10);
            const points = try allocator.alloc(poly.point, n2*4);
            var sq = try allocator.alloc(poly.point, 4);
            defer allocator.free(sq);
            defer allocator.free(points);
            var sumArea: f64 = 0;

            for (0..n2) |r| {
                const x = try std.fmt.parseFloat(f64, splitter.next().?);
                const y = try std.fmt.parseFloat(f64, splitter.next().?);
                const w = try std.fmt.parseFloat(f64, splitter.next().?);
                const h = try std.fmt.parseFloat(f64, splitter.next().?);
                const v = try std.fmt.parseFloat(f64, splitter.next().?);
                sq= translateCordinates(x, y, w, h, v, sq);

                sumArea += w*h;

                for (0..sq.len) |i| {
                    points[r*4 + i] = .{.x= sq[i].x, .y=sq[i].y };
                }
            }

            const resHull = try poly.Convex_Hull(points, allocator);
            defer allocator.free(resHull);
            const areaHull = @abs(poly.polygon_area(resHull));

            const procent: f64 =  (sumArea/areaHull) * 100;
            try writer.print("{d:.1} %\n", .{procent});        

        }
    }
    
    try buffered.flush();
}


fn translateCordinates(x:f64, y:f64, w:f64, h:f64, v:f64, sq: []poly.point) []poly.point {
    const vip: f64 = v*(std.math.pi / 180.0);
    const c: f64 = std.math.cos(vip);
    const s: f64 = std.math.sin(vip);
    const h2: f64 = h/2;
    const w2: f64 = w/2;

    sq[0] = .{ .x = x - w2*c - h2 * s, .y = y+w2 * s - h2 * c };
    sq[1] = .{ .x = x - w2*c + h2 * s, .y = y+w2 * s + h2 * c };
    sq[2] = .{ .x = x + w2*c + h2 * s, .y = y-w2 * s + h2 * c };
    sq[3] = .{ .x = x + w2*c - h2 * s, .y = y-w2 * s - h2 * c };

    return sq;
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

