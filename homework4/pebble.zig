/// Author: Felix Stenberg
///
const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}

pub fn printResults(res: bool) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();
    if (res) {
        try writer.print("yes\n", .{});
    } else {
        try writer.print("no\n", .{});
    }

    try buffered.flush();
}

///Start by parsing into a dubble array


fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const n = try std.fmt.parseInt(usize, splitter.next().?, 10);
    
    var i: usize = 0;
    var memo = try allocator.alloc(i32, 8388608);
    @memset(memo, -1);
    defer allocator.free(memo);
    memo[0] = -1;

    var result = try allocator.alloc(i32, n);
    @memset(result, -1);
    defer allocator.free(result);


    while (i < n) : (i += 1) {
        var input: usize = 0;
        const in = splitter.next().?;
        var countStones: i32 = 0;
        for (in, 0..) |value, indx| {
            var tempVal: usize = 0;
            if (value == 'o') {
                tempVal = 1;
                tempVal = tempVal << @intCast(indx);
                countStones += 1;
            } else {
                tempVal = tempVal << @intCast(indx); 
            }
            input = input | tempVal;
        }

        // std.debug.print("input:\n{b} \n", .{input});

        if (memo[input] != -1) {
            result[i] = memo[input];
            // std.debug.print("final removed stones: {d}\n", .{result[i]});
            // std.debug.print("\n-----\n\n", .{});
        } else {
            const removedStones = try solve(input, memo);
            // std.debug.print("final removed stones: {d}\n", .{removedStones});
            // std.debug.print("\n-----\n\n", .{});
            result[i] = countStones - removedStones;
        }
    }
    // std.debug.print("{any}\n", .{result});

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();
    for (result) |value| {
        try writer.print("{d}\n", .{value});
    }
    try buffered.flush();

}


//Can jump over if there are two stones adjacent and there is a hole on the other side

//might want to do this reqrsuively and try each starting point, then back track which one is correct and then memo 
//the result for like [sum this far, index], so we don't do repeat tries, we will also have to run from
// back and front? 
// Maybe can use the same function back and forward?

//Maybe actually start from a valid starting point and then try from each valid starting point?
//So we go through until we find valid starting point, i valid starting point, we run that
//If not valid we keep looking, how to memo though? We could translate the board to an int and store it as is in an array
//If this patern has been seen before and we have calculated it we can then just pull that value

//Scrap bool array use an i32 D:


fn solve(input: usize, memo: []i32) !i32 {
    if (memo[input] != -1) {
        return memo[input];
    }

    var max_stones: i32 = 0;

    // Check all possible positions for stones
    for (0..23) |currBit| {
        if (!checkCurBit(currBit, input)) continue;

        // Try to jump right (to lower index)
        if (currBit >= 2) {
            if (checkCurBit(currBit - 1, input) and !checkCurBit(currBit - 2, input)) {
                const newInput = jumpRight(currBit, input);
                const res = 1 + try solve(newInput, memo);
                max_stones = @max(max_stones, res);
            }
        }

        // Try to jump left (to higher index)
        if (currBit < 21) { // Ensure currBit + 2 < 23 
            if (checkCurBit(currBit + 1, input) and !checkCurBit(currBit + 2, input)) {
                const newInput = jumpLeft(currBit, input);
                const res = 1 + try solve(newInput, memo);
                max_stones = @max(max_stones, res);
            }
        }
    }


    memo[input] = max_stones;    
    return max_stones;
}

// We check for each if we can jump right/left
// Otherwise we move on to the next potential stone

fn checkCurBit(b: usize, input: usize) bool {
    const one: usize = 1;
    const mask: usize =  one << @intCast(b);
    return (input & mask) != 0;
}

fn jumpLeft(currBit: usize, input: usize) usize {
    var newInput = input;
    const one: usize = 1;
    newInput &= ~(one << @intCast(currBit));
    var left:u6  = @intCast(currBit + 1);
    newInput &= ~(one << left);
    left += 1;
    newInput |= (one << left);
    return newInput;
}

fn jumpRight(currBit: usize, input: usize) usize {
    var newInput = input;
    const one: usize = 1;
    newInput &= ~(one << @intCast(currBit));
    var right:u6 = @intCast(currBit-1);
    newInput &= ~(one << right);
    right -= 1;
    newInput |= (one << right);
    return newInput;
} 

// fn jump(currBit: u6, input: usize) !usize {

// }


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