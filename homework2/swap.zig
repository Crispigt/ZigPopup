/// Author: Felix Stenberg
/// 
/// 

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

pub fn printResults(res: bool) !void {
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();
    if (res) {
        try writer.print("yes\n", .{});
    }else{
        try writer.print("no\n", .{});
    }
    
    try buffered.flush();
}
pub fn NodeArray(comptime T: type) type {
    return struct {
        parent: T,
        rank: u32,
    };
}

pub fn UnionFindArray(comptime T: type) type {
    return struct {
        const Self = @This();
        const NodeType = NodeArray(T);

        allocator: std.mem.Allocator,
        nodes: []NodeType,

        pub fn init(allocator: std.mem.Allocator, size: usize) !Self {
            const nodes = try allocator.alloc(NodeType, size);
            for (nodes, 0..) |*node, i| {
                const val: T = std.math.cast(T, i).?;
                node.parent = val;
                node.rank = 0;
            }
            return Self{
                .allocator = allocator,
                .nodes = nodes,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.nodes);
        }

        pub fn unionN(self: *Self, a: T, b: T) void {
            const root_a = self.find(a);
            const root_b = self.find(b);
            if (root_a == root_b) return;

            if (self.nodes[root_a].rank > self.nodes[root_b].rank) {
                self.nodes[root_b].parent = root_a;
            } else if (self.nodes[root_a].rank < self.nodes[root_b].rank) {
                self.nodes[root_a].parent = root_b;
            } else {
                self.nodes[root_b].parent = root_a;
                self.nodes[root_a].rank += 1;
            }
        }
        /// Return true if a and b are in the same component
        pub fn same(self: *Self, a: T, b: T) bool {
            return self.find(a) == self.find(b);
        }

        pub fn find(self: *Self, value: T) T {
            const index = @as(usize, @intCast(value));
            var node = &self.nodes[index];
            if (node.parent != value) {
                const root = self.find(node.parent);
                node.parent = root;
                return root;
            }
            return value;
        }
    };
}

/// We know that the center element will be stationary if it is a odd number
/// then we can check if there are pairs for each in the same way we checked in the first asignment
/// 
/// We need to find swaps for each element that brings it back to it's original location
/// 
/// Maybe we can represent swaps as vertices in a graph
/// 
/// and we know that node 1 can get to it's right place if there exists a path to max node 
/// 
/// Maybe we can just use union find
/// 
/// We union all the nodes, then for each swap that has to happen, we check if their in the same :D 
/// 
fn parseAndRunCombinedArray(comptime T: type, data: []u8, allocator: std.mem.Allocator) !bool {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const N = try std.fmt.parseInt(T, splitter.next().?, 10);
    _ = splitter.next();

    var uni = try UnionFindArray(T).init(allocator, N+1);

    while (splitter.next()) |token| {
        if (std.mem.eql(u8,token, "")) {
            continue;
        }
        const a = try std.fmt.parseInt(T, token, 10);
        const b = try std.fmt.parseInt(T, splitter.next().?, 10);
        // std.debug.print("a: {d}, b: {d}\n", .{a, b});
        uni.unionN(a, b);
    }
    
    var dupK = N;
    for (1..N/2+1) |value| {
        const t = uni.same(value, dupK);
        // std.debug.print("res: {any}, value: {d} and dupK: {d}\n", .{t, value, dupK});
        if (!t){
            return t;
        }
        dupK -= 1;
    }
    return true;
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