/// Author: Felix Stenberg
/// 
/// Connar takes the three values and puts them in order
/// 
/// 1 2 3
///
/// 3 3 2 1
/// 3 1 2 3
/// 1 2 3 3
/// 
/// Easiest might just be to do the the swaps and count them
/// go from the back, take 
/// 
/// Is there any data strukture that can help me out here?
/// 
/// Keep track of the number that needs to swap the furthest, each time it can move two steps, 
/// so if it has to go from position 4 to 1 it needs two swaps, etc, when this is done all of the other elements
/// will be swaped in the mean time with the two other variables thereby counting how many swaps are needed
/// might only work if 
/// 
/// We can track the amount of swaps based on how many elements before the current element is greater than the element, 
/// and how many elements after the current element are less than element, these needs to be swaped,
/// this is because each pair from will form a valid triple, then since each of them can form a pair
/// with each on the other side we have to multiply so we take the sum of both sides and mulitply with both
/// 
/// So how can we do this effiecently well we can probably use some sort of fennwick tree
/// When we move in the array we can count each element that is less than this element and add to the fennwick
/// This would give us the total of less than for each element up to this, then we would now for future reference that we have already counted all less
/// than up to this value  
/// 
/// 3 3 2 1
/// 
/// 3 has no prev that is higher
/// 3 has 2 later that is lower
/// gives 0 * 2
/// 
/// 2 has 2 prev that is higher
/// and one later that is lower
/// giver 2 * 1 = 2 
/// 

pub fn FennWick(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        bittree: []T,

        pub fn init(allocator: std.mem.Allocator, size: usize) !Self {
            const bittree = try allocator.alloc(T, size + 1);
            for (bittree) |*bit| {
                bit.* = 0;
            }
            return Self{
                .allocator = allocator,
                .bittree = bittree,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.bittree);
        }

        pub fn add(self: *Self, index: usize, number: T) void {
            var indx = index + 1;
            while (indx < self.bittree.len) {
                self.bittree[indx] += number;
                indx += indx & -%indx;
            }
        }

        pub fn sum(self: *Self, index: usize) T {
            var summation: T = 0;
            var indx = index;

            while (indx > 0) {
                summation += self.bittree[indx];
                indx -= indx & -%indx;
            }

            return summation;
        }
    };
}


const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}

fn parseNextToken(comptime T: type, splitter: anytype) !T {
    while (splitter.next()) |token| {
        if (token.len == 0) continue;
        return switch (T) {
            []const u8 => token,
            else => try std.fmt.parseInt(T, token, 10),
        };
    }
    return error.UnexpectedEndOfInput;
}

pub fn printResults(res: usize) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();
    
    try writer.print("{d}\n", .{res});
    
    try buffered.flush();
}

fn parseAndRunCombinedArray(comptime T: type, data: []u8, allocator: std.mem.Allocator) !T {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const size = try std.fmt.parseInt(T, splitter.next().?, 10);
    var fennyL = try FennWick(T).init(allocator, size+1);
    defer fennyL.deinit();

    const inputData = try allocator.alloc(T,size);
    const L = try allocator.alloc(T,size);
    defer allocator.free(L);
    defer allocator.free(inputData);


    var maxSize: T = 0;
    var currSize: usize = 0;
    while (splitter.next()) |token| {
        if (std.mem.eql(u8,token, "")) {
            continue;
        }
        const value = try std.fmt.parseInt(T, token, 10);
        if (value > maxSize) maxSize = value;
        // std.debug.print("Val: {d}\n", .{value});
        const sumToLeft = fennyL.sum(value+1);
        // std.debug.print("sumL: {d}\n", .{sumToLeft});

        L[currSize] = currSize - sumToLeft;
        // std.debug.print("added: {d}\n", .{L[currSize]});

        fennyL.add(value, 1);
        inputData[currSize] = value;
        currSize +=1; 
    }

    // if we have
    // 3 3
    // then we will have added one to fennwick 3 from the first one
    // then when we get to the second one, we only want to count larger numbers right
    // so when we do sum(3) we get 1 and then 1 - 1  is 0
    // but then when we have 3 3 2
    // we look sum(2) and find that no lower numbers have been added which
    // tells us that all the previous numbers were larger :D And then we do for the next number etc

    var fennyR = try FennWick(T).init(allocator, size);    
    defer fennyR.deinit();
    const R = try allocator.alloc(T,size);
    defer allocator.free(R);

    var i = size;
    currSize = 0;
    while (i > 0){
        i -=1;
        const value = inputData[i];
        // std.debug.print("Val R: {d} \n", .{value});
        const sumToRight = fennyR.sum(value);
        R[i] = sumToRight;
        // std.debug.print("added R: {d}\n", .{sumToRight});
        fennyR.add(value, 1);
    }

    // Here we are looking for smaller values right so we look
    // 3 3 2 1
    // well then we can just look at the sum to that value for each
    // which gives us the amount of lower values have come before
    // so for 1 that would be zero but we add 1 to 1
    // now when we sum(2) we will count that 1
    // giving us 1
    // for 3 this will be 2 and 2 

    var res: T = 0;
    // const diff: T = size - maxSize;
    // std.debug.print("diff:{d}\n", .{diff});
    for (0..size) |indxd| {
        res += L[indxd] * R[indxd];
        // std.debug.print("l: {d}, r: {d}\n", .{L[indxd], R[indxd]});
    } 
    // std.debug.print("res: {d}\n", .{res});
    // std.debug.print("sums: {d}, {d}, {d}\n", .{fennyL.sum(1), fennyL.sum(2), fennyL.sum(maxSize)});
    // std.debug.print("sums: {d}, {d}, {d}\n", .{fennyR.sum(1), fennyR.sum(2), fennyR.sum(maxSize)});

    // std.debug.print("L: {any}\n", .{L});
    // std.debug.print("R: {any}\n", .{R});

    return res;
}


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

    const testing = try parseAndRunCombinedArray(usize, all_data,allocator,);

    // std.debug.print("this is res: \n", .{});
    try printResults(testing);

    buffer[1] = '1';
}