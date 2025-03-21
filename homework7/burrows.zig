/// Author: Felix Stenberg
///
///
const std = @import("std");

const IX = struct {
    index: usize,
    rank: [2]i32,
};

pub fn compareIX(_: void, a: IX, b: IX) bool {
    if (a.rank[0] == b.rank[0]) {
        return a.rank[1] < b.rank[1];
    } else {
        return a.rank[0] < b.rank[0];
    }
}

pub fn buildSuffixArr(allocator: std.mem.Allocator, word: []const u8) ![]usize {
    const n = word.len;
    var suffixes = try allocator.alloc(IX, n);
    defer allocator.free(suffixes);

    for (word, 0..) |char, i| {
        suffixes[i] = .{
            .index = i,
            .rank = .{
                @as(i32, char),
                if (i + 1 < n) @as(i32, word[i + 1]) else -1,
            },
        };
    }

    std.mem.sort(IX, suffixes, {}, compareIX);

    var indx = try allocator.alloc(usize, n);
    defer allocator.free(indx);

    var k: usize = 2;
    while (k < 2 * n) : (k *= 2) {
        var rank: i32 = 0;
        var prev_rank = suffixes[0].rank[0];
        suffixes[0].rank[0] = rank;
        indx[suffixes[0].index] = 0;

        for (1..n) |r| {
            if (suffixes[r].rank[0] == prev_rank and
                suffixes[r].rank[1] == suffixes[r - 1].rank[1])
            {
                prev_rank = suffixes[r].rank[0];
                suffixes[r].rank[0] = rank;
            } else {
                prev_rank = suffixes[r].rank[0];
                rank += 1;
                suffixes[r].rank[0] = rank;
            }
            indx[suffixes[r].index] = r;
        }

        for (suffixes) |*suffix| {
            const next_index = suffix.index + k / 2;
            suffix.rank[1] = if (next_index < n)
             suffixes[indx[next_index]].rank[0] else -1;
        }
        std.mem.sort(IX, suffixes, {}, compareIX);
    }

    var suffix_arr = try allocator.alloc(usize, n);
    for (suffixes, 0..) |suffix, i| {
        suffix_arr[i] = suffix.index;
    }

    return suffix_arr;
}

pub fn bwt(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const n = input.len;
    if (n == 0) return try allocator.alloc(u8, 0);

    var T = try allocator.alloc(u8, 2 * n);
    defer allocator.free(T);
    std.mem.copyForwards(u8, T[0..n], input);
    std.mem.copyForwards(u8, T[n..], input);

    const suffixArr = try buildSuffixArr(allocator, T);
    defer allocator.free(suffixArr);

    var sorted_rotations = std.ArrayList(usize).init(allocator);
    defer sorted_rotations.deinit();
    for (suffixArr) |entry| {
        if (entry < n) {
            try sorted_rotations.append(entry);
        }
    }

    var result = try allocator.alloc(u8, n);
    for (sorted_rotations.items, 0..) |i, idx| {
        const prev = (i + n - 1) % n;
        result[idx] = input[prev];
    }

    return result;
}

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const allocator = std.heap.page_allocator;

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();


    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    var buffer = std.ArrayList(u8).init(aa);

    while (true) {
        buffer.clearRetainingCapacity();
        stdin.streamUntilDelimiter(buffer.writer(), '\n', null) catch |err| {
        if (err == error.EndOfStream) {
            if (buffer.items.len != 0) {
                const line = buffer.items;
                const transformed = try bwt(aa, line);
                defer aa.free(transformed);
                try writer.print("{s}\n", .{transformed});
            }
            break;
        } else {
            return err;
        }
        };

        const line = buffer.items;
        if (line.len == 0) continue;

        const transformed = try bwt(aa, line);
        defer aa.free(transformed);
        try writer.print("{s}\n", .{transformed});
    }
    try buffered.flush();
}