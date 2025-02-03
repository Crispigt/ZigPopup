/// Author: Felix Stenberg
const std = @import("std");

/// Node structure
pub fn Node(comptime T: type) type {
    return struct {
        pub const Self = @This();
        value: T,
        parent: *Self,
        length: u32 = 0,
    };
}

pub fn UnionFind(comptime T: type) type {
    return struct {
        const Self = @This();
        const NodeType = Node(T);
        const NodePtr = *NodeType;
        const MapType = std.AutoHashMap(T, NodePtr);

        allocator: std.mem.Allocator,
        nodes: MapType,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .nodes = MapType.init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            // var it = self.nodes.valueIterator();
            // while (it.next()) |node| {
            //     self.allocator.destroy(node.*);
            // }
            self.nodes.deinit();
        }

        ///Create original sets
        pub fn makeSet(self: *Self, value: T) !*Node(T) {
            // if (!self.nodes.contains(value)) {
            const node = try self.allocator.create(Node(T));
            node.value = value;
            node.parent = node; // Parent is self initially
            node.length = 0;
            try self.nodes.put(value, node);
            return node;
            // }

        }

        /// Indicate that set a and b are merged
        ///
        /// PS. union is special word in zig it seems like
        pub fn unioN(self: *Self, a: T, b: T) !void {
            const root_a = try self.findRoot(a);
            const root_b = try self.findRoot(b);

            // Already united
            if (root_a == root_b) return;

            // Union by longest tree
            if (root_a.length > root_b.length) {
                root_b.parent = root_a;
            } else if (root_a.length < root_b.length) {
                root_a.parent = root_b;
            } else {
                root_b.parent = root_a;
                root_a.length += 1;
            }
        }

        /// Checks if a and b are in same set
        ///
        ///
        pub fn same(self: *Self, a: T, b: T) !bool {
            const root_a = try self.findRoot(a);
            const root_b = try self.findRoot(b);
            return root_a == root_b;
        }

        fn findRoot(self: *Self, child_value: T) !*Node(T) {
            const child = self.nodes.get(child_value);

            if (child) |childAlive| {
                var current = childAlive;
                // Find root node, and compress path to flatten the tree
                while (current.parent != current) {
                    current.parent = current.parent.parent;
                    current = current.parent;
                }

                return current;
            } else {
                const newNode = try self.makeSet(child_value);
                return newNode;
            }
        }
    };
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

//Need to make a good find function to know if a b are in the same set
//This is needed for both same and for union since we are supposed to add
//These together

//Because if we do this, we can just when we query go up to the
//root parent which if it's a balanced tree should be log(n) to find
//and if it is the same root for both we are happy

//We also need to do some sort of balancing
//Do as we said on lecture to just add smaller tree to root of larger
//And we can use path compression so we minimize tree while quering

//Also need to make a parser that can build the sets
//Base set is fully disjunct, so each will just be a number
//Probably easiest to keep track of all of them in an array
//or maybe a hashmap actually if we want to keep track of something else than numbers

// = is a and b are joined
// ? query if a and b are in the same set

// Should I keep track of size somehow, add the smaller tree to the larger ones root so somehow balance it

// Maybe keep track of depth somehow for example everytime we add a new node through union we add one to the previous depth
// Then if depth goes over a certain threshold we find root and add parts of the larger branch to the root
// For example lets say we have depth 16, we go up to depth 8 and detach and add this to root instead, thereby halving our depth

/// Reads entire input into a buffer without size restrictions.
pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}

/// Parses input tokens into strings
pub fn parseTokens(comptime T: type, allocator: std.mem.Allocator, data: []const u8) ![]T {
    var tokens = std.ArrayList(T).init(allocator);
    var splitter = std.mem.splitAny(u8, data, " \n");

    while (splitter.next()) |token| {
        if (token.len == 0) continue;

        const owned_token = try allocator.alloc(u8, token.len);
        std.mem.copyForwards(u8, owned_token, token);

        try tokens.append(owned_token);
    }

    return tokens.toOwnedSlice();
}

pub fn parseAndRun(allocator: anytype, input: [][]u8) ![]bool {
    const N = try std.fmt.parseInt(usize, input[0], 10);
    const Q = try std.fmt.parseInt(usize, input[1], 10);

    //Create inital base set from N
    var unionF = UnionFind(i32).init(allocator);
    defer unionF.deinit();

    var valAsInt: i32 = 0;
    for (0..N) |value| {
        valAsInt = @intCast(value);
        try unionF.makeSet(valAsInt);
    }

    var result = std.ArrayList(bool).init(allocator);
    defer result.deinit();
    //Loop through Q queries
    var i: usize = 2;
    var a: i32 = 0;
    var b: i32 = 0;
    while (i < Q * 3) {
        a = try std.fmt.parseInt(i32, input[i + 1], 10);
        b = try std.fmt.parseInt(i32, input[i + 2], 10);
        // std.debug.print("Now we have on {d}: {d}, {d}\n", .{i,a,b});
        if (std.mem.eql(u8, input[i], "=")) {
            try unionF.unioN(a, b);
            // std.debug.print("union: {d}, {d}\n", .{a,b});
        } else {
            try result.append(try unionF.same(a, b));
            // std.debug.print("same: {d}, {d}\n", .{a,b});
        }
        i += 3;
    }
    return result.toOwnedSlice();
}

pub fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []const u8) ![]bool {
    var splitter = std.mem.splitAny(u8, data, " \n");

    // Parse N and Q
    const N = try parseNextToken(usize, &splitter);
    const Q = try parseNextToken(usize, &splitter);

    // Initialize Union-Find structure
    var unionF = try UnionFindArray(u32).init(allocator, N);
    defer unionF.deinit();

    // std.debug.print("Here\n", .{});

    var result = std.ArrayList(bool).init(allocator);
    defer result.deinit();

    // Process each query
    var q: usize = 0;
    while (q < Q) : (q += 1) {
        const op = try parseNextToken([]const u8, &splitter);
        const a = try parseNextToken(u32, &splitter);
        const b = try parseNextToken(u32, &splitter);

        if (std.mem.eql(u8, op, "=")) {
            unionF.unionN(a, b);
        } else {
            const sameResult = unionF.same(a, b);
            try result.append(sameResult);
        }
    }

    return result.toOwnedSlice();
}

pub fn parseAndRunCombined(allocator: std.mem.Allocator, data: []const u8) ![]bool {
    var splitter = std.mem.splitAny(u8, data, " \n");

    // Parse N and Q
    _ = try parseNextToken(usize, &splitter);
    const Q = try parseNextToken(usize, &splitter);

    // Initialize Union-Find structure
    var unionF = UnionFind(i32).init(allocator);
    defer unionF.deinit();
    // for (0..N) |value| {
    //     // std.debug.print("{d}\n", .{value});
    //     try unionF.makeSet(@intCast(value));
    // }

    // std.debug.print("Here\n", .{});

    var result = std.ArrayList(bool).init(allocator);
    defer result.deinit();

    // Process each query
    var q: usize = 0;
    while (q < Q) : (q += 1) {
        const op = try parseNextToken([]const u8, &splitter);
        const a = try parseNextToken(i32, &splitter);
        const b = try parseNextToken(i32, &splitter);
        // std.debug.print("we are on", .{});
        if (std.mem.eql(u8, op, "=")) {
            try unionF.unioN(a, b);
        } else {
            const sameResult = try unionF.same(a, b);
            try result.append(sameResult);
        }
    }
    // std.debug.print("Why does it break", .{});
    return result.toOwnedSlice();
}

// Helper to parse the next token from the splitter.
fn parseNextToken(comptime T: type, splitter: anytype) !T {
    while (splitter.next()) |token| {
        if (token.len == 0) continue;
        return switch (T) {
            []const u8 => token, // Use the slice directly without allocation
            else => try std.fmt.parseInt(T, token, 10),
        };
    }
    return error.UnexpectedEndOfInput;
}

pub fn printResults(res: []bool) !void {
    const stdout = std.io.getStdOut();
    for (res) |value| {
        if (value) {
            try stdout.writeAll("yes\n");
        } else {
            try stdout.writeAll("no\n");
        }
    }
}

pub fn printResults2(allocator: anytype, res: []bool) !void {
    const stdout = std.io.getStdOut();
    var resultPrint = std.ArrayList(u8).init(allocator);
    for (res) |value| {
        if (value) {
            try resultPrint.appendSlice("yes\n");
        } else {
            try resultPrint.appendSlice("no\n");
        }
    }
    const resultPrint1 = try resultPrint.toOwnedSlice();
    try stdout.writeAll(resultPrint1);
}
