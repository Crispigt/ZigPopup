/// Author: Felix Stenberg
const std = @import("std");


/// + Indicates that a[i] is incremented by the second value 
/// ? is a query to find the result
/// 
/// 
/// We want to have a tree in the array, 
/// 

pub fn FennWick(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        bittree: []T,

        pub fn init(allocator: std.mem.Allocator, size: usize) !Self {
            const bittree = try allocator.alloc(T, size + 1);
            for (bittree) |*bit| {
                bit.* = 0;
            }
            return Self{
                .allocator = allocator,
                .bittree = bittree,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.bittree);
        }

        pub fn add(self: *Self, index: usize, number: T) void {
            var indx = index + 1;
            while (indx < self.bittree.len) {
                self.bittree[indx] += number;
                indx += indx & -%indx;
            }
        }

        pub fn sum(self: *Self, index: usize) T {
            var summation: T = 0;
            var indx = index;

            while (indx > 0) {
                summation += self.bittree[indx];
                indx -= indx & -%indx;
            }

            return summation;
        }
    };
}

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}

pub fn parseAndRunCombinedArray(comptime T: type, allocator: std.mem.Allocator, data: []const u8) ![]T {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const N = try parseNextToken(usize, &splitter);
    const Q = try parseNextToken(usize, &splitter);

    var fennwick = try FennWick(T).init(allocator, N);
    defer fennwick.deinit();

    var result = std.ArrayList(T).init(allocator);
    defer result.deinit();

    var q: usize = 0;
    while (q < Q) : (q += 1) {
        const op = try parseNextToken([]const u8, &splitter);
        if (std.mem.eql(u8, op, "+")) {
            const a = try parseNextToken(usize, &splitter);
            const b = try parseNextToken(T, &splitter);
            fennwick.add(a, b);
        } else {
            const a = try parseNextToken(usize, &splitter);
            const r = fennwick.sum(a);
            try result.append(r);
        }
    }
    return result.toOwnedSlice();
}

fn parseNextToken(comptime T: type, splitter: anytype) !T {
    while (splitter.next()) |token| {
        if (token.len == 0) continue;
        return switch (T) {
            []const u8 => token,
            else => try std.fmt.parseInt(T, token, 10),
        };
    }
    return error.UnexpectedEndOfInput;
}

pub fn printResults(res: []i64) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    for (res) |value| {
        try writer.print("{d}\n", .{value});
    }

    try buffered.flush();
}