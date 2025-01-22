///
/// Author: Felix Stenberg
/// 
/// Seems like we have to compare each of the words to the word on the earlier line
/// we then store this word for that var, if we come to the same var
/// and we check above word and it is wrong the thing doesn't work
/// Need to check both way because the var can be different for both ways
///
/// Transpose each var with words and check against other if we can match them
///
///
/// we can map each word to specific location in array so 1 goes to one, makes it easier to comapare what is there
///
///
const std = @import("std");
const read = @import("stdInput.zig");
const list= std.ArrayList;

pub fn solveAll(input: std.ArrayList([]u8), allocator: anytype) !std.ArrayList([]const u8) {
    var res = std.ArrayList([]const u8).init(allocator);
    const inputArray = input.items;
    const amount: i32 = try std.fmt.parseInt(i32, inputArray[0], 10);
    var ac: usize = 1;
    // std.debug.print("{d}\n", .{amount});
    for(1..@intCast(amount+1))|i|{
        ac = i*2-1;
        // std.debug.print("ac: {d}\n", .{ac});
        // std.debug.print("line 1: {s}, line 2: {s} \n", .{inputArray[ac], inputArray[ac+1]});
        const line = try helpMeSolve(inputArray[ac], inputArray[ac + 1], allocator);  
        try res.append(line);
    }
    return res;
}

pub fn helpMeSolve(line1: []u8, line2: []u8, allocator: anytype) ![]const u8 {

    var res = std.ArrayList(u8).init(allocator);
    var res2 = std.ArrayList(u8).init(allocator);
    // var res2 = std.ArrayList(u8).init(allocator); 


    const line1split = try read.splitByDelimiter(line1, " ", allocator);
    const line2split = try read.splitByDelimiter(line2, " ", allocator);
    defer line1split.deinit();
    defer line2split.deinit();


    var line1Hashmap =  std.HashMap([]const u8, usize, std.hash_map.StringContext, 99).init(allocator);
    var line2Hashmap =  std.HashMap([]const u8, usize, std.hash_map.StringContext, 99).init(allocator);
    defer line1Hashmap.deinit();
    defer line2Hashmap.deinit();


    var count: usize = 0;
    for (line1split.items) |value| {
        // std.debug.print("{s} ", .{value});
        if (value[0] == '<') {
            const variable = line1Hashmap.get(value);
            const aboveLine = line2split.items[count]; 
            if(variable)| variable1|{
                if (std.mem.eql(u8, line2split.items[variable1], aboveLine)) {
                    // std.debug.print("problem solve", .{});

                    return "-";
                }
            }else {
                try line1Hashmap.put(@as([]const u8, value), count);
                try res.appendSlice(aboveLine[0..]);
                try res.append(' ');
                count +=1;
                continue;
            }
            
        }
        try res.appendSlice(value[0..]);
        try res.append(' ');        
        count +=1;
    }
    count = 0;
    for (line2split.items) |value| {
        // std.debug.print("{s} ", .{value});
        if (value[0] == '<') {
            const variable = line2Hashmap.get(value);
            const aboveLine = line1split.items[count]; 
            if(variable)| variable1|{
                if (std.mem.eql(u8, line1split.items[variable1], aboveLine)) {
                    // std.debug.print("problem solve", .{});

                    return "-";
                }
            }else {
                try line2Hashmap.put(@as([]const u8, value), count);
                try res2.appendSlice(aboveLine[0..]);
                try res2.append(' ');
                count +=1;
                continue;
            }
            
        }
        try res2.appendSlice(value[0..]);
        try res2.append(' ');        
        count +=1;
    }

    const result = try res.toOwnedSlice();
    const result2 =  try res2.toOwnedSlice();
    if (std.mem.eql(u8,result,result2)) {
        return result;
    }
    return "-";
}

pub fn printRes(res: std.ArrayList([]const u8)) !void {
    const stdout = std.io.getStdOut();
    for (res.items) |value| {
        try stdout.writer().print("{s}\n", .{value});
    }

}



// another thing I could do is just build the string while going along and then in the key value part we just store a value back to the position of the word we where going to point there, that way it goes way faster probably, 
// we arrive with two built strings thereby not having to test different things and build a string  





// if < string > check if the var i already used, then compare this to position in other line or add the potentiall val
// otherwise add this as this lines permanent version
// what happens if the other lines position is a var, maybe we can just do the compare at the same time
// Compare the two lines potentiall versions and check if they are the same if they are it's a match

// problem prob is if both have a var from each side that is do not have the same word
