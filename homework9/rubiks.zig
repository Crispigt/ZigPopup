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

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    var filtered_list = std.ArrayList(u8).init(allocator);
    defer filtered_list.deinit();

    var is: u32 = 0;
    var count: u8 = 0;
    for (data) |byte| {
        const val: u8 = switch (byte) {
            'R' => 0,
            'G' => 1,
            'B' => 2,
            'Y' => 3,
            else => continue,
        };
        is |= @as(u32, val) << @as(u5, @intCast(count * 2));
        count += 1;
    }

    const t: u32 = 0xFFAA5500;

    if (is == t) {
        try writer.print("0\n", .{});
        try buffered.flush();
        return;
    }

    var queueForward = std.fifo.LinearFifo(struct { state: u32, depth: u8 }, .Dynamic).init(allocator);
    defer queueForward.deinit();
    try queueForward.writeItem(.{ .state = is, .depth = 0 });

    var queueBack = std.fifo.LinearFifo(struct { state: u32, depth: u8 }, .Dynamic).init(allocator);
    defer queueBack.deinit();
    try queueBack.writeItem(.{ .state = t, .depth = 0 });

    var forwardVisited = std.AutoHashMap(u32, u8).init(allocator);
    defer forwardVisited.deinit();
    try forwardVisited.put(is, 0);

    var backwardVisited = std.AutoHashMap(u32, u8).init(allocator);
    defer backwardVisited.deinit();
    try backwardVisited.put(t, 0);

    var ans: u8 = undefined;
    var found = false;

    while (true) {

        const forwSize = queueForward.readableLength();
        if (forwSize > 0) {
            for (0..forwSize) |_| {
                const current = queueForward.readItem() orelse unreachable;

                if (backwardVisited.get(current.state)) |bd| {
                    ans = current.depth + bd;
                    found = true;
                    break;
                }

                if (current.depth >= 13) continue;

                for (0..4) |row| {
                    const sl = shiftRowLeft(current.state, row);
                    const sr = shiftRowRight(current.state, row);

                    if (!forwardVisited.contains(sl)) {
                        try forwardVisited.put(sl, current.depth + 1);
                        try queueForward.writeItem(.{ .state = sl, .depth = current.depth + 1 });

                        if (backwardVisited.get(sl)) |bd| {
                            ans = current.depth + 1 + bd;
                            found = true;
                            break;
                        }
                    }

                    if (!forwardVisited.contains(sr)) {
                        try forwardVisited.put(sr, current.depth + 1);
                        try queueForward.writeItem(.{ .state = sr, .depth = current.depth + 1 });

                        if (backwardVisited.get(sr)) |bd| {
                            ans = current.depth + 1 + bd;
                            found = true;
                            break;
                        }
                    }
                }
                if (found) break;

                for (0..4) |col| {
                    const su = shiftColumnUp(current.state, col);
                    const sd = shiftColumnDown(current.state, col);

                    if (!forwardVisited.contains(su)) {
                        try forwardVisited.put(su, current.depth + 1);
                        try queueForward.writeItem(.{ .state = su, .depth = current.depth + 1 });

                        if (backwardVisited.get(su)) |bd| {
                            ans = current.depth + 1 + bd;
                            found = true;
                            break;
                        }
                    }

                    if (!forwardVisited.contains(sd)) {
                        try forwardVisited.put(sd, current.depth + 1);
                        try queueForward.writeItem(.{ .state = sd, .depth = current.depth + 1 });

                        if (backwardVisited.get(sd)) |bd| {
                            ans = current.depth + 1 + bd;
                            found = true;
                            break;
                        }
                    }
                }
                if (found) break;
            }
        }
        if (found) break;

        const backSize = queueBack.readableLength();
        if (backSize > 0) {
            for (0..backSize) |_| {
                const current = queueBack.readItem() orelse unreachable;


                if (forwardVisited.get(current.state)) |fd| {
                    ans = current.depth + fd;
                    found = true;
                    break;
                }

                if (current.depth >= 13) continue;

                for (0..4) |row| {
                    const sl = shiftRowLeft(current.state, row);
                    const sr = shiftRowRight(current.state, row);

                    if (!backwardVisited.contains(sl)) {
                        try backwardVisited.put(sl, current.depth + 1);
                        try queueBack.writeItem(.{ .state = sl, .depth = current.depth + 1 });

                        if (forwardVisited.get(sl)) |fd| {
                            ans = current.depth + 1 + fd;
                            found = true;
                            break;
                        }
                    }

                    if (!backwardVisited.contains(sr)) {
                        try backwardVisited.put(sr, current.depth + 1);
                        try queueBack.writeItem(.{ .state = sr, .depth = current.depth + 1 });

                        if (forwardVisited.get(sr)) |fd| {
                            ans = current.depth + 1 + fd;
                            found = true;
                            break;
                        }
                    }
                }
                if (found) break;

                for (0..4) |col| {
                    const su = shiftColumnUp(current.state, col);
                    const sd = shiftColumnDown(current.state, col);

                    if (!backwardVisited.contains(su)) {
                        try backwardVisited.put(su, current.depth + 1);
                        try queueBack.writeItem(.{ .state = su, .depth = current.depth + 1 });

                        if (forwardVisited.get(su)) |fd| {
                            ans = current.depth + 1 + fd;
                            found = true;
                            break;
                        }
                    }

                    if (!backwardVisited.contains(sd)) {
                        try backwardVisited.put(sd, current.depth + 1);
                        try queueBack.writeItem(.{ .state = sd, .depth = current.depth + 1 });

                        if (forwardVisited.get(sd)) |fd| {
                            ans = current.depth + 1 + fd;
                            found = true;
                            break;
                        }
                    }
                }
                if (found) break;
            }
        }
        if (found) break;

        if (queueForward.readableLength() == 0 and queueBack.readableLength() == 0) {
            try writer.writeAll("fuck");
            break;
        }
    }

    try writer.print("{d}\n", .{ans});
    try buffered.flush();
}

fn shiftRowLeft(state: u32, row: usize) u32 {
    const rowNum = @as(u5, @intCast(row * 8));
    const currRow: u8 = @truncate((state >> rowNum));
    const shifted = ((currRow << 2) & 0xFF) | (currRow >> 6);
    return (state & ~(@as(u32, 0xFF) << rowNum)) | (@as(u32, shifted) << rowNum);
}

fn shiftRowRight(state: u32, row: usize) u32 {
    const rowNum = @as(u5, @intCast(row * 8));
    const currRow: u8 = @truncate((state >> rowNum));
    const shifted = (currRow >> 2) | ((currRow & 0x03) << 6);
    return (state & ~(@as(u32, 0xFF) << rowNum)) | (@as(u32, shifted) << rowNum);
}

fn shiftColumnUp(state: u32, col: usize) u32 {
    const c0 = (state >> @as(u5, @intCast(col * 2))) & 0x3;
    const c1 = (state >> @as(u5, @intCast((4 + col) * 2))) & 0x3;
    const c2 = (state >> @as(u5, @intCast((8 + col) * 2))) & 0x3;
    const c3 = (state >> @as(u5, @intCast((12 + col) * 2))) & 0x3;

    var newState = state;

    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast(col * 2)));
    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast((4 + col) * 2)));
    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast((8 + col) * 2)));
    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast((12 + col) * 2)));

    newState |= (c1 << @as(u5, @intCast(col * 2)));
    newState |= (c2 << @as(u5, @intCast((4 + col) * 2)));
    newState |= (c3 << @as(u5, @intCast((8 + col) * 2)));
    newState |= (c0 << @as(u5, @intCast((12 + col) * 2)));

    return newState;
}

fn shiftColumnDown(state: u32, col: usize) u32 {
    const c0 = (state >> @as(u5, @intCast(col * 2))) & 0x3;
    const c1 = (state >> @as(u5, @intCast((4 + col) * 2))) & 0x3;
    const c2 = (state >> @as(u5, @intCast((8 + col) * 2))) & 0x3;
    const c3 = (state >> @as(u5, @intCast((12 + col) * 2))) & 0x3;

    var newState = state;

    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast(col * 2)));
    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast((4 + col) * 2)));
    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast((8 + col) * 2)));
    newState &= ~(@as(u32, 0x3) << @as(u5, @intCast((12 + col) * 2)));

    newState |= (c3 << @as(u5, @intCast(col * 2)));
    newState |= (c0 << @as(u5, @intCast((4 + col) * 2)));
    newState |= (c1 << @as(u5, @intCast((8 + col) * 2)));
    newState |= (c2 << @as(u5, @intCast((12 + col) * 2)));

    return newState;
}