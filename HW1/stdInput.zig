const std = @import("std");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

/// Reads a single line (until `\n`) from `reader` into `buffer`.
/// Returns the slice of data if successful or `null` if EOF is reached.
///
/// - Parameters:
///   - `reader`: the stream from which to read
///   - `buffer`: a temporary buffer for reading
///
/// - Returns: `?[]u8` representing the line read, or `null` if no line was read
fn readLineToVariable(reader: anytype, buffer: []u8) !?[]u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
    return line orelse null;
}

/// Reads a single token from `reader` until a space (' ') delimiter is found or EOF.
/// Returns the slice of data if successful or `null` if EOF is reached.
///
/// - Parameters:
///   - `reader`: the stream from which to read
///   - `buffer`: a temporary buffer for reading
///
/// - Returns: `?[]const u8` representing the token read, or `null` if no token was read
fn readCharEndSpace(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, ' ');
    return line orelse null; // Handle the case where no more lines are available
}


/// Splits multiple input lines by the specified `delimiter` and parses each token into `i32`.
/// For each line in `input`, it will:
///   1. Split the line into tokens (using `delimiter`).
///   2. Parse each token as `i32`.
///   3. Store each line's integer tokens in a separate slice.
///
/// - Parameters:
///   - `input`: a list of byte slices, each element being one line (e.g. ["123,456", "789,10"])
///   - `delimiter`: the delimiter that may consist of multiple bytes (e.g. ",")
///   - `allocator`: an allocator to manage memory for the resulting array
///
/// - Returns: a `std.ArrayList([]i32)`, where each element corresponds to a line's parsed integers
///
/// - Throws: any errors from allocation or integer parsing
pub fn delimiterStringToInt(
    input: std.ArrayList([]u8),
    delimiter: []const u8,
    allocator: anytype,
) !std.ArrayList([]i32) {
    var result = std.ArrayList([]i32).init(allocator);

    for (input.items) |line| {
        // Split the line into tokens.
        var tokens = try splitByDelimiter(line, delimiter, allocator);

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

/// Reads the entire input (line by line) from `stdin`,
/// appends it to a single `std.ArrayList(u8)`, and returns it.
///
/// - Parameters:
///   - `allocator`: the allocator used for creating the output buffer
///   - `stdin`: the standard input stream
///   - `buffer`: a temporary buffer used for reading chunks
///
/// - Returns: `std.ArrayList(u8)` containing all the read data (with `\n` separating lines)
///
/// - Throws: any error from reading the stream or appending data
pub fn readFullInput(allocator: anytype, stdin: anytype, buffer: []u8) !std.ArrayList(u8) {
    var input = try readLineToVariable(stdin.reader(), buffer[0..]);
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

/// Reads the entire input (line by line) from `reader`,
/// storing each full line as its own allocated slice in `std.ArrayList([]u8)`.
///
/// - Parameters:
///   - `allocator`: the allocator used for each line read
///   - `reader`: the stream from which to read
///   - `buffer`: a temporary buffer for reading lines
///
/// - Returns: `std.ArrayList([]u8)` where each item is a separately allocated line
///
/// - Throws: any error from reading the stream or allocating memory
pub fn readFullInputArrays(allocator: anytype, reader: anytype, buffer: []u8) !std.ArrayList([]u8) {
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

