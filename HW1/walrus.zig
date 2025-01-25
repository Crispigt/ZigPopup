
/// 
/// Author: Felix Stenberg
/// 
/// 
///
/// 
const std = @import("std");


//Greedy way is just to add upp and take the value that is closest, we could probably improve by sorting

/// 900
/// 500
/// 498
/// 4
/// 
/// We first go for 900
/// 
/// save as our closest to 900
/// 
/// 900, second we get 500 goes above 1000
/// then we go for next number
/// 
/// 500 check against 498
/// 
/// 
/// 
/// 
/// 
/// 
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

var ClosestNum: i32 = std.math.maxInt(i32);

var memo: std.AutoHashMap(u64, i32) = std.AutoHashMap(u64, i32).init(allocator);

fn makeKey(n: usize, currSum: i32) u64 {
    const n_as_u64 = @as(u64, n); // Convert `n` to u64
    const currSum_as_u64: u64 =@intCast(currSum); // Bit-cast i32 to u64
    return (n_as_u64 << 32) | currSum_as_u64;
}



fn walrus2(input: [][]i32, n: usize, currSum:i32) !i32 {
    const closness: i32 = 1000 - currSum; 

    const key = makeKey(n, currSum);
    if (memo.get(key)) |cached_value| {
        // std.debug.print("returned cached: {d}\n", .{cached_value});
        return cached_value;
    }
    if(0 >= closness){
        // std.debug.print("went past 1000, {d}\n", .{closness});
        memo.put(key, currSum) catch unreachable;
        return currSum;
    }

    //We are at the end of array so we need to return
    if(n <= 1) {
        memo.put(key, currSum) catch unreachable;    
        return currSum;
    }


    const pathOne = try walrus2(input, n - 1, currSum);
    if (pathOne == 1000) {
        memo.put(key, 1000) catch unreachable;
        return 1000; 
    }
    const pathTwo: i32 = try walrus2(input, n-1, currSum + input[n-1][0] ); 

    // std.debug.print("{d}\n", .{currSum});
    var return_val: i32 = 0;
    if (@abs(1000 - pathOne) < @abs(1000 - pathTwo)) {
        return_val = pathOne;
    } else if (@abs(1000 - pathOne) == @abs(1000 - pathTwo)) {
        return_val = @max(pathOne, pathTwo);
    } else {
        return_val = pathTwo;
    }
    memo.put(key, return_val) catch unreachable;
    return return_val;
}






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


    // for (intArray.items) |value| {
    //     std.debug.print("{d}\n", .{value});
    // }

    const inputArray = try intArray.toOwnedSlice();

    // for (inputArray) |value| {
    //     std.debug.print("{d}", .{value});
    // }
    // std.debug.print("\n", .{});

    ClosestNum = try walrus2(inputArray, inputArray.len, 0);

    // const end = try Instant.now();

    // const elapsed1: f64 = @floatFromInt(end.since(start));
    // std.debug.print("Time elapsed is: {d:.3}ms\n", .{
    //     elapsed1 / time.ns_per_ms,
    // });
    // std.debug.print("Here it is: \n", .{});
    const stdout = std.io.getStdOut();
    try stdout.writer().print("{d}\n", .{ClosestNum});


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