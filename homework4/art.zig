/// Author: Felix Stenberg
///
const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}


/// Simplest approach would just be to look for the lowest value rooms and check if we can strike them
/// 
/// Could look for the lowest sum subset that doesn't break the rules and add upp to k rooms
/// 
/// if room choosen, can not choose the one next to it and above next to it
/// 
/// Otherwise look at it like a graph, what path if we remove k nodes is the optimal path 
/// 
/// We can also just try all combinations reqursively and then use memorisation
/// 
/// branch of for one down/uppwards, and then one up/downards diagonaly, memo on index and already covered positions?
/// 
/// memo on x,y index, so from here you can get as best result this
/// 
/// 
fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    var ccc: i32 = 0;

    while (true) {
        const n = try std.fmt.parseInt(usize, splitter.next().?, 10);
        const k = try std.fmt.parseInt(usize, splitter.next().?, 10);

        if (n == 0 and k == 0) {
            if (ccc == 0) {
                try writer.print("0\n", .{});
            }
            break;
        }
        ccc += 1;
        const rooms = try allocator.alloc([]usize, n);

        for (rooms) |*room| {
            room.* = try allocator.alloc(usize, 2);
        }

        const xy = try allocator.alloc([][]usize, k);

        for (xy) |*xRow| {
            xRow.* = try allocator.alloc([]usize, n);
            for (xRow.*) |*cell| {
                cell.* = try allocator.alloc(usize, 3);
                @memset(cell.*, std.math.maxInt(usize));
            }
        }

        var tot: usize = 0;
        for (rooms) |room| {
            room[0] = try std.fmt.parseInt(usize, splitter.next().?, 10);
            room[1] = try std.fmt.parseInt(usize, splitter.next().?, 10);
            tot += room[0] + room[1];
        }

        const left = solveLeftSide(k, 0, rooms, xy, 0, 0);

        const minLoss: usize = left;

        const final = tot - minLoss;

        try writer.print("{d}\n", .{final});
    }
    try buffered.flush();
}

fn solveLeftSide(k: usize, count: usize, input: [][]usize, memo: [][][]usize, y: usize, last: usize) usize {
    if (count == k) {
        return 0;
    }
    if (y >= input.len) {
        return 10000000000;
    }
    if (memo[count][y][last] != std.math.maxInt(usize)) {
        return memo[count][y][last];
    }

    var minLoss: usize = std.math.maxInt(usize);

    if (last != 2) {
        const left = input[y][0] + solveLeftSide(k, count + 1, input, memo, y + 1, 1);
        minLoss = left;
    }

    if (last != 1) {
        const right = input[y][1] + solveLeftSide(k, count + 1, input, memo, y + 1, 2);
        minLoss = @min(minLoss, right);
    }

    const clean = solveLeftSide(k, count, input, memo, y + 1, 0);
    minLoss = @min(minLoss, clean);

    memo[count][y][last] = minLoss;
    return minLoss;
}


//we want min instead


// One problem now is that I only start in the top left and not in top right, but I guess I could just 
// run this twice with start in top right as well, everything will already be mem so should be fine

// Keep last some how and then just go through by row basis and if the lastone was closed diagonally do not close this one
// 

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

    try parseAndRunCombinedArray(allocator,all_data);

    // std.debug.print("this is res: \n", .{});
    // try printResults(testing);

    buffer[1] = '1';
}