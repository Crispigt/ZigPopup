/// Author: Felix Stenberg
const std = @import("std");
const cover = @import("intervalCover.zig");
const stdInput = @import("stdInput.zig");

fn toUsize(value: anytype) usize {
    return switch (@typeInfo(@TypeOf(value))) {
        .Float => @intFromFloat(value),
        .Int => @intCast(value),
        else => @compileError("Unsupported type for conversion to usize"),
    };
}

pub fn parseAndRun(comptime T: type, input: [][]T, allocator: anytype) ![][]usize {
    var res = std.ArrayList([]usize).init(allocator);
    const IntervalType = cover.Interval(T);
    var count: usize = 0;
    //std.debug.print("\nlen: {any}\n", .{input.len});
    while (count < input.len) {
        const targetInterval = IntervalType{
            .start = input[count][0],
            .end = input[count][1],
            .index = count,
        };
        //std.debug.print("interval: {any}\n", .{input[count]});
        count +=1;

        const num_intervals = toUsize(input[count][0]);
        //std.debug.print("num_interval: {any}\n", .{num_intervals});
        count +=1;

        var intervals = std.ArrayList(IntervalType).init(allocator);
        defer intervals.deinit();
        var indexForIntervalls: usize = 0;
        for (count..num_intervals + count) |row| {
            try intervals.append(IntervalType{
                .start = input[row][0],
                .end = input[row][1],
                .index = indexForIntervalls,
            });
            indexForIntervalls += 1;
            //std.debug.print("intervals: {any}\n", .{input[row]});
        }
        count += num_intervals;
        
        const testResult = try cover.cover(T, allocator, targetInterval, intervals.items);

        //std.debug.print("res: {any}\n", .{testResult});
        try res.append(testResult);
    }
    
    return res.toOwnedSlice();
}

pub fn printCoverage(result: [][]usize) !void {
    const stdout = std.io.getStdOut();
    for (result) |value| {
        if (value.len != 0) {
            try stdout.writer().print("{d}\n", .{value.len});
            for (value) |indecies| {
                try stdout.writer().print("{d} ", .{indecies});
            }
            try stdout.writeAll("\n");
        } else {
            try stdout.writeAll("impossible\n");
        }
    }

}

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const allocator = std.heap.page_allocator;
    var buffer: [1024]u8 = undefined;

    const input = try stdInput.readFullInputArrays(allocator, stdin.reader(), buffer[0..]);
    // for (input.items) |s| {
    //     for (s) |c| {
    //         //std.debug.print("{c}", .{c});
    //     }
    //     //std.debug.print("\n", .{});
    // }

    var floatArray = try stdInput.delimiterStringToFloat32(input, " ", allocator);

    // const start = try Instant.now();
    
    const Array: [][]f32 = try floatArray.toOwnedSlice();

    // for (Array) |value| {
    //     //std.debug.print("{any}", .{value});
    // }

    const testing = try parseAndRun(f32,Array, allocator);
    try printCoverage(testing);

    // for (inputInf32) |vi| {
    //     std.debug.print("Value: {d}, Original Index: {d}\n", .{vi.value, vi.index});
    // }

    // std.debug.print("{d}\n", .{countRooms});
    // for (inputArray) |value| {
    //     std.debug.print("{d} ", .{value});
    // }
    // std.debug.print("\n", .{});



    // const stdout = std.io.getStdOut();
    // if (t) {
    //     for (valueIndexArray) |value| {
    //         try stdout.writer().print("{d} ", .{value.index + 1});
    //     }
    //     try stdout.writeAll("\n");
    // } else {
    //     try stdout.writeAll("impossible\n");
    // }


    // const end = try Instant.now();

    // const elapsed1: f32 = @floatFromInt(end.since(start));
    // std.debug.print("Time elapsed is: {d:.3}ms\n", .{
    //     elapsed1 / time.ns_per_ms,
    // });
    // std.debug.print("Here it is: \n", .{});


    buffer[1] = '1';

    // for (floatArray.items) |s| {
    //     for (s) |d| {
    //         std.debug.print("{d} ", .{d});
    //     }
    //     std.debug.print("\n", .{});
    // }

    for (input.items) |value| {
        allocator.free(value);
    }
    input.deinit();
    for (floatArray.items) |value| {
        allocator.free(value);
    }
    floatArray.deinit();
}   