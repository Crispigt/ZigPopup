///
///Author: Felix Stenberg
///
const std = @import("std");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;


///Top car moved to bottom
/// TWo cards moved one at a time to bottom
/// Next card is dealt face up and is Ace of Spades
/// Three cards moved one at a time
/// goes on until the nth and last card turns out to be the n of spades
/// 
/// Program has to determine initial order ofcards for given number of cards
/// 
/// -Input n test cases <= 13 
/// -Each case consists of one line with n [1..13]
/// 
/// Are all cards spades?
/// 4
/// 2 1 4 3 - takes one card moves it to the bottom shows ace
/// 4 3 2   - takes two cards moves to bottom shows 2
/// 4 3     - takes 3 cards, so moves 4, 3, 4, shows 3
/// 4       - shows number 4
/// 
/// First of 1 will allways be position 2
/// 
/// We can think of it like a long list of numbers
/// or
/// a list that loops around in essence
/// to get to the desired number we need it to rotate to the correct position for it's turn
/// 
/// so for turn 2 we need to rotate 2 into position 2 relative to the length of the thing,
/// think this gives us 
/// 
/// 
/// 5
/// 3 1 4 5 2
/// 4 5 2 3
/// 3 4 5
/// 4 5
/// 5
/// 
/// 3
/// 3 1 2
/// 3 2
/// 3
/// 
/// x 1 x
/// 
/// 
/// 
/// 
/// 3 1 3 5 2
/// 
/// Easiest way to do it is probably just to do it step by step, we look at the length of the list, place one where it needs to go, then place 2 
///  
///   2   4       8         13          
/// x 1 x x 2 x x x 3 x x x x 4 x x x x x 5 
/// 
/// Tänker oss som en for loop som går igenom antalet platser som är kvar, vart behöver vi placera 
/// 
/// Kanske lättare att börja från andra hållet, att vi bygger upp arrayen, vi börjar med sista talet t.ex. 5, måste placeras på plats 1 i en 1 lång array, sedan i 2 lång array behöver 4 placeras i 
/// 
/// We build it from the back, create array, look okay first we need place the last one obviously in the only spot, then we need to place the next one either to the left or right depending on mod 2
/// then the next one we have to put depending on mod 3, and where ever we place we move the previous array behind it rapping around
/// 
/// 
/// 

fn readLineToVariable(reader: anytype, buffer: []u8) !?[]u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
    return line orelse null;
}


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



pub fn sovle(input: std.ArrayList([]i32), allocator: anytype) !std.ArrayList([]i32) {
    var res = std.ArrayList([]i32).init(allocator);
    var count:i32 = 0;
    for (input.items) |value| {
        if (count != 0) {
        const temp = try allocator.alloc(i32, @intCast(value[0]));   
        const temp1 = try returnSolved(value[0], allocator);
        defer allocator.free(temp1);
        std.mem.copyForwards(i32, temp, temp1);
        try res.append(temp);
        }
        count +=1;
    }
    return res;
}

fn returnSolved(number: i32, allocator: anytype) ![]i32{
    var res = try allocator.alloc(i32, @intCast(number));   
    var size: i32 = 1;
    var number1: i32 = number;
    while(true){
        if(number1 == 0 ){
            break;
        }
        const pos = @mod(number1, size);
        res = try shiftArrayAndInsert(pos, size, number1, res,number,allocator);

        size += 1;
        number1-=1;
    }
    return res;
}

fn shiftArrayAndInsert(pos: i32, size: i32, number: i32 , res: []i32, fullsize: i32,allocator: anytype) ![]i32
{
    const posU: usize = @intCast(pos);
    const sizeU: usize = @intCast(size);

    const amountOfShift = posU+1;

    var newPos: usize = 0;
    const temp = try allocator.alloc(i32, @intCast(fullsize)); 

    std.mem.copyForwards(i32, temp, res);
    for (temp, 0..) |value, i| {
        newPos = @mod(i + amountOfShift, sizeU);

        res[newPos] = value;
        if (i == size-1) {break;}
    }
    res[posU] = number;

    allocator.free(temp);
    return res;
}


pub fn printResult(res: std.ArrayList([]i32)) !void {
    const stdout = std.io.getStdOut();
    for (res.items) |value| {
        for (value) |d| {
            try stdout.writer().print("{d} ", .{d});
        }
        try stdout.writeAll("\n");
    }
}


pub fn main() !void {

    const stdin = std.io.getStdIn();

    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;

    const input = try readFullInputArrays(allocator, stdin.reader(), buffer[0..]);

    // for (input.items) |s| {
    //     for (s) |c| {
    //         std.debug.print("{c}", .{c});
    //     }
    //     std.debug.print("\n", .{});
    // }

    const intArray = try delimiterStringToInt(input, " ", allocator);

    // const start = try Instant.now();
    
    const res = try sovle(intArray, allocator);
    try printResult(res);

    // const end = try Instant.now();

    // const elapsed1: f64 = @floatFromInt(end.since(start));
    // std.debug.print("Time elapsed is: {d:.3}ms\n", .{
    //     elapsed1 / time.ns_per_ms,
    // });





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