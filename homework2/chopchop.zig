/// Author: Felix Stenberg
///
///
///
/// What we actually want to do is rebuild the structure
///
/// Input length of list, and then the v column
///
/// output if only one tree is possible output the string that was all the cut of nodes
/// if ambigous output "Error"
///
/// Do we know that all the nodes are upp the the first value?
///
/// v will be all the parents, so we know that the children under vi will be
///
/// Maybe we can utilize union find somehow by making components and then when we see something we add them together
///
/// Only a child node when it has no children at all
///
/// When we only have two nodes, we will always choose the lower node
///
/// if we later on find a value that is lower than the previous value we know that that value must be upstream the previous value
///
/// so if we see 5 and later on 1 we know that 5 was below 1
///
/// The largest number, that is n + 1 will always be the "root" or the number that gets deleted last
///
/// Last val in the list is also the one connected to the last value
///
/// Maybe rebuild from the back, the last step needs to be the 2 node structure
///
/// Last value in v needs to be largest value, the second last needs to be the one before the largest
///
/// then the next new value we now is the connected to this, and if there are more r
///
/// we then keep track of these extra variables, they need to be
///
/// We know that for nodes on the same level we the one that comes last is the one that has the larger value
///
/// We know that a tree won't exist if the sum of degrees is not divisible by 2
///
/// degree = freq of value in list + 1
///
/// root degree is it's freq
///
/// By knowing their degree we know when we they become a leaf node
///
/// or start with all of the nodes not present in the v list these are the child nodes
/// we add these to a heap to dynamically sort them
///
/// for first v we know can pick the lowest we then know that we have
///
/// We expect node values to be 1-max
/// We count the frequency when making them into an int array
/// Here we also find the root(max) value, which will be the last value and also n + 1, check so that last value is n + 1 otherwise it is false
/// We also add up the total degrees and check so that it is divisible by two
/// We can keep track of the children by intializing all of them with degree 1
///
///
///
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

pub fn printResults(res: []i64) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    for (res) |value| {
        try writer.print("{d}\n", .{value});
    }

    try buffered.flush();
}

fn compare(comptime T: type) type {
    return struct {
        fn compareMinHeap(_: void, a: T, b: T) bool {
            return a < b;
        }
    };
}

fn parseAndRunCombinedArray(comptime T: type, data: []u8, allocator: std.mem.Allocator) ![]T {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const root = try std.fmt.parseInt(T, splitter.next().?, 10) + 1;

    const freq = try allocator.alloc(T, root + 1); // maybe need + 1 because all values will be from 1
    defer allocator.free(freq);
    @memset(freq, 1);

    var totFreq = root;
    while (splitter.next()) |token| {
        const value = try std.fmt.parseInt(T, token, 10);
        freq[value] += 1;
        totFreq += 1;
    }
    // We can check afterwards if root also had atleast one vertice

    var minHeap = std.PriorityQueue(u32, void, compare(T).compareMinHeap()).init(allocator, {});
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

    const testing = try parseAndRunCombinedArray(i64, allocator, all_data);

    defer allocator.free(testing);

    try fenwick.printResults(testing);

    buffer[1] = '1';
}
