
/// 
/// Author: Felix Stenberg
/// 
/// 
///
/// 
const std = @import("std");

fn readLineToVariable(reader: anytype, buffer: []u8) !?[]u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
    return line orelse null;
}

pub fn readFullInputArrays(reader: anytype, buffer: []u8) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(allocator);
    var input = try readLineToVariable(reader, buffer[0..]);

    while (input) |line| {
        const temp = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, temp, line);
        try lines.append(temp);
        input = try readLineToVariable(reader, buffer[0..]);
    }

    return lines;
}
pub fn delimiterStringToInt(
    input: std.ArrayList([]u8),
    delimiter: []const u8
) !std.ArrayList([]i32) {
    var result = std.ArrayList([]i32).init(allocator);

    for (input.items) |line| {
        // Split the line into tokens.
        var tokens = try splitByDelimiter(line, delimiter);

        // Parse each token into i32.
        var numbers = std.ArrayList(i32).init(allocator);
        for (tokens.items) |token| {
            if (token.len == 0) continue;
            const parsed = try std.fmt.parseInt(i32, token, 10);
            try numbers.append(parsed);
        }

        // Turn our dynamic list of i32 into an owned slice, then store it in the final result.
        const owned_slice: []i32 = try numbers.toOwnedSlice();
        try result.append(owned_slice);

        numbers.deinit();
        tokens.deinit();
    }

    return result;
}

/// Splits `line` into tokens, using a multi-byte `delimiter`.
/// Returns a list of slices pointing to the original memory (no extra copy).
///
/// - Parameters:
///   - `line`: the byte slice to split
///   - `delimiter`: the multi-byte delimiter
///   - `allocator`: the allocator to use for creating the tokens list
///
/// - Returns: `std.ArrayList([]u8)` whose items are slices of `line`
///
/// - Throws: any error from the allocator
pub fn splitByDelimiter(
    line: []u8,
    delimiter: []const u8
) !std.ArrayList([]u8) {
    var tokens = std.ArrayList([]u8).init(allocator);
    var start: usize = 0;
    var i: usize = 0;

    while (i < line.len) {
        if (i + delimiter.len <= line.len and
            std.mem.eql(u8, line[i .. i + delimiter.len], delimiter))
        {
            // We found the delimiter:
            // everything from `start` up to `i` is a token.
            try tokens.append(line[start..i]);

            // Skip over the delimiter and set up the new token start.
            i += delimiter.len;
            start = i;
        } else {
            i += 1;
        }
    }

    // Capture the final token (if any characters remain after the last delimiter).
    if (start < line.len) {
        try tokens.append(line[start..line.len]);
    }

    return tokens;
}




// In 

// Need to be atleast n^2
const allocator = std.heap.page_allocator;


/// In essence we need to have enough pappers each time as the total amount of the next room we go to
/// We have to get rid of all the pappers from each room so no room can have more pappers than the combination of the rest
/// Is it sum sub but for each individual room? maybe?
/// 
/// Maybe easiest to go to the next room that is less than or equal to the current room size?
/// 
/// First take the largest room, so in essence sort, ascending, than keep track of the original rooms size, count so that we get rid of everything from that rooom and keep track so that we have enough pappers  



fn sovle(input: []ValueIndex, len: usize) !bool {
    var firstRoomSize = input[0].value;
    var runningTot: i32 = input[0].value;
    // std.debug.print("firstRoomSize: {d}, runningtot: {d}\n", .{firstRoomSize,runningTot});
    for (1..len) |value| {
        firstRoomSize -= input[value].value;
        runningTot -= input[value].value;
        // std.debug.print("firstRoomSize: {d}, runningtot: {d}\n", .{firstRoomSize,runningTot});
        if (runningTot < 0) {
            //Break
            return false;
        }
        runningTot += input[value].value;
    }
    // std.debug.print("firstRoomSize: {d}, runningtot: {d}\n", .{firstRoomSize,runningTot});
    runningTot -= input[0].value;
    if (runningTot < 0 or firstRoomSize > 0) {
        return false;
    }
    return true;
}


const ValueIndex = struct {
    value: i32,
    index: usize,

    pub fn compare(_: void, a: ValueIndex, b: ValueIndex) bool {
        return a.value > b.value; // Descending order
    }
};


pub fn main() !void {
    const stdin = std.io.getStdIn();

    var buffer: [1024]u8 = undefined;

    const input = try readFullInputArrays( stdin.reader(), buffer[0..]);

    // for (input.items) |s| {
    //     for (s) |c| {
    //         std.debug.print("{c}", .{c});
    //     }
    //     std.debug.print("\n", .{});
    // }

    var intArray = try delimiterStringToInt(input, " ");

    // const start = try Instant.now();
    
    // We want to save prev values some how, we can put in for 

    const Array: [][]i32 = try intArray.toOwnedSlice();

    const countRooms: usize = @intCast(Array[0][0]);

    const inputArray: []i32 = Array[1];


    var valueIndexArray = try allocator.alloc(ValueIndex, inputArray.len);
    defer allocator.free(valueIndexArray);

    for (inputArray, 0..) |val, idx| {
        valueIndexArray[idx] = .{ .value = val, .index = idx };
    }

    std.mem.sort(ValueIndex, valueIndexArray, {}, ValueIndex.compare) ;

    // for (valueIndexArray) |vi| {
    //     std.debug.print("Value: {d}, Original Index: {d}\n", .{vi.value, vi.index});
    // }

    // std.debug.print("{d}\n", .{countRooms});
    // for (inputArray) |value| {
    //     std.debug.print("{d} ", .{value});
    // }
    // std.debug.print("\n", .{});

    const t = try sovle(valueIndexArray, countRooms);

    const stdout = std.io.getStdOut();
    if (t) {
        for (valueIndexArray) |value| {
            try stdout.writer().print("{d} ", .{value.index + 1});
        }
        try stdout.writeAll("\n");
    } else {
        try stdout.writeAll("impossible\n");
    }


    // const end = try Instant.now();

    // const elapsed1: f64 = @floatFromInt(end.since(start));
    // std.debug.print("Time elapsed is: {d:.3}ms\n", .{
    //     elapsed1 / time.ns_per_ms,
    // });
    // std.debug.print("Here it is: \n", .{});


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