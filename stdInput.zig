const std = @import("std");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

fn readLineToVariable(reader: anytype, buffer: []u8) !?[]u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
    return line orelse null;
}

fn readCharEndSpace(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, ' ');
    return line orelse null; // Handle the case where no more lines are available
}

fn convertfuckingstringtoint(input: ?[]const u8) !i32 {
    var ret: i32 = 0;
    if (input) |value| {
        const trimshit = std.mem.trim(u8, value, " \n\r");
        ret = try std.fmt.parseInt(i32, trimshit, 10);
        //std.debug.print("converted: {d}\n", .{ret});
        return ret;
    }
    return 0;
}

// fn delimiterStringToInt(input: std.ArrayList([]u8), delimiter: u8, allocator: anytype) std.ArrayList([]i32) {
//     var res = std.ArrayList([]i32).init(allocator);
//     var resInt: i32 = 0;
//     for (input.items) |lines| {
//         const linesTrim = std.mem.trim(u8, lines, delimiter);
//         // If something between each number then it will be the len divided by the len of the delimiter - 1 right?
//         var temp = try allocator.alloc(i32, (linesTrim.len / delimiter.len));
//         var count: usize = 0;
//         var sizeNum: usize = 0;
//         var startNum: usize = 0;

//         for (linesTrim) |value| {
//             if (value != delimiter) {
//                 sizeNum +=1;
//             }else {
//                 resInt = try std.fmt.parseInt(i32, linesTrim[startNum..sizeNum], 10);
//                 temp[count] = resInt;
//                 count += 1;
//                 sizeNum = 0;
//             }
//             startNum += 1;
//         }
//         try res.append(temp);
//     }
//     return res;
// }

pub fn delimiterStringToInt(
    input: std.ArrayList([]u8), // e.g. ["123,456", "789,10", "11,12"]
    delimiter: []const u8, // multi-byte delimiter, e.g. ","
    allocator: anytype,
) !std.ArrayList([]i32) {
    // The final result is an array list of slices of i32:
    // each line in the input becomes one slice.
    var result = std.ArrayList([]i32).init(allocator);

    // For each line in the input, split by the delimiter string,
    // parse all tokens, and build a slice of i32s.
    for (input.items) |line| {
        // 1) Split the line into tokens by the multi-byte delimiter.
        var tokens = try splitByDelimiter(line, delimiter, allocator);

        // 2) Parse each token into i32.
        var numbers = std.ArrayList(i32).init(allocator);
        for (tokens.items) |token| {
            // Skip if token is empty (e.g. if you had consecutive delimiters).
            if (token.len == 0) continue;

            // Convert token (e.g. "123") to i32.
            const parsed = try std.fmt.parseInt(i32, token, 10);
            try numbers.append(parsed);
        }

        // 3) Turn our dynamic list of i32 into an owned slice,
        //    then store that slice in the final result.
        const owned_slice: []i32 = try numbers.toOwnedSlice();

        try result.append(owned_slice);

        // 4) De-init the temporary allocations.
        numbers.deinit();
        tokens.deinit();
    }

    return result;
}

/// Splits `line` into tokens separated by the multi-byte `delimiter`.
/// Returns an ArrayList of slices (no extra copying for each token).
fn splitByDelimiter(
    line: []u8,
    delimiter: []const u8,
    allocator: anytype,
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

fn stringToInt() !void {}

fn readFullInput(allocator: anytype, stdin: anytype, buffer: []u8) !std.ArrayList(u8) {

    // Read each line and store it in the lines array
    var input = try readLineToVariable(stdin.reader(), buffer[0..]);
    //Either re alloc every time new mem or use a arraylist or what its called
    var fullString = std.ArrayList(u8).init(allocator);
    while (true) {
        if (input) |real| {
            try fullString.appendSlice(real);
            try fullString.append('\n');
        } else {
            break;
        }
        input = try readLineToVariable(stdin.reader(), buffer[0..]);
    }

    return fullString;
}

fn readFullInputArrays(allocator: anytype, reader: anytype, buffer: []u8) !std.ArrayList([]u8) {
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

pub fn main() !void {
    const stdin = std.io.getStdIn();

    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;

    const input = try readFullInputArrays(allocator, stdin.reader(), buffer[0..]);

    for (input.items) |s| {
        for (s) |c| {
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }

    const please = try delimiterStringToInt(input, " ", allocator);

    buffer[1] = '1';

    for (please.items) |s| {
        for (s) |d| {
            std.debug.print("{d} ", .{d});
        }
        std.debug.print("\n", .{});
    }

    for (input.items) |value| {
        allocator.free(value);
    }
    input.deinit();
    for (please.items) |value| {
        allocator.free(value);
    }
    please.deinit();
}
