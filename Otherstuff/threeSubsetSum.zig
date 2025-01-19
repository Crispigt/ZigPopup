const std = @import("std");
const read = @import("stdInput.zig");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

fn solveSubSet(nList: std.ArrayList([]i32), allocator: anytype) !?[]i32 {
    const n = nList.items[0][0];
    const t = nList.items[0][1];    
    std.debug.print("n: {d}, t: {d}\n", .{n,t});
    var layer1: i32 = 0;
    var layer2: i32 = 0;
    for (nList.items) |v| {
        layer1 = v[0];
        for (nList.items) |v2| {
            layer2 = v2[0];
            for (nList.items) |v3| {
                if (layer1 != layer2 and layer1 != v3[0] and layer2 != v3[0] and layer1 + layer2 + v3[0] == t) {
                    const temp = try allocator.alloc(i32, 3);
                    temp[0] = layer1;
                    temp[1] = layer2;
                    temp[2] = v3[0];
                    return temp;
                }
            }
        }
    }
    return null;
}

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

    const start = try Instant.now();
    const res = try solveSubSet(intArray, allocator); 
    const end = try Instant.now();

    const elapsed1: f64 = @floatFromInt(end.since(start));
    std.debug.print("Time elapsed is: {d:.3}ms\n", .{
        elapsed1 / time.ns_per_ms,
    });

    if (res)|res1| {
        std.debug.print("this is res:{d}\n", .{res1});
    } else {
        std.debug.print("No match found\n", .{});
    }



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
