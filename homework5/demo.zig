/// Author: Felix Stenberg
///
const std = @import("std");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}


const Node = struct {
    pointers: std.ArrayList(usize), // Since all of the nodes are
};

const Graph = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    nodes: []std.ArrayList(usize),
    visit: []bool,
    countNodes: usize,
    queue: std.ArrayList(usize),

    fn init(allocator: std.mem.Allocator, n: usize) !Self {
        const nodes = try allocator.alloc(std.ArrayList(usize), n);
        const visit = try allocator.alloc(bool, n);
        @memset(visit, false);
        const queue = std.ArrayList(usize).init(allocator);
        for (nodes) |*node| {
            node.* = std.ArrayList(usize).init(allocator);
        }
        return Self{
            .allocator = allocator,
            .nodes = nodes,
            .visit = visit,
            .countNodes = n,
            .queue = queue,
        };
    }

    fn denit(self: *Self) void {
        for (self.nodes) |value| {
            value.deinit();
        }
        self.allocator.free(self.nodes);
        self.allocator.free(self.visit);
        self.queue.deinit();
    }

    ///Add edge from u to v
    fn addEdge(self: *Self, u: usize, v: usize  ) !void{
        try self.nodes[u].append(v);
    }

    ///Check if we have any
    fn checkWin(self: *Self, u: usize) !bool {
        var count: usize = 0;
        try self.queue.append(u);
        self.visit[u] = true;
        count += 1;

        var front: usize = 0;
        // std.debug.print("\nlooking at {d}\n", .{u});
        while (front < self.queue.items.len) : (front += 1) {
            const current = self.queue.items[front];
            // std.debug.print("current: {d}\n", .{current});
            const neighbors = self.nodes[current];
            // std.debug.print("neighbours: {any}\n", .{neighbors.items});
            for (neighbors.items) |value| {
                if (!self.visit[value]) {
                    self.visit[value] = true;
                    count += 1;
                    // std.debug.print("found: {d}\n", .{value});
                    try self.queue.append(value); // Only add unvisited neighbors to the queue
                }
            }
        }

        // Reset the visit array and clear the queue for future use
        @memset(self.visit, false);
        self.queue.clearAndFree();

        // std.debug.print("count: {d}\n", .{count});
        return count == self.countNodes;
    }

};

fn add(x: usize, y: usize, value: i32, arr: []i32, n: usize) !void {
    arr[x*n + y] += value;
}

fn convert(u: u8) usize{
    const char: u8 = 'A';
    return @intCast(u-char);
}

fn convertBack(u: usize) u8{
    const char: u8 = 'A';
    return @intCast(u+char);
}

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const n = try std.fmt.parseInt(usize, splitter.next().?, 10);
    const m = try std.fmt.parseInt(usize, splitter.next().?, 10);
    // std.debug.print("{d} {d}\n", .{n, m});


    const compareArray = try allocator.alloc(i32, n*n);
    defer allocator.free(compareArray);
    @memset(compareArray, 0);

    // Save previous values and then for each new value we add for the previous values

    var i:usize = 0;
    var prev = std.ArrayList(usize).init(allocator);
    defer prev.deinit();
    while (i < m) : (i+=1){
        const value = try std.fmt.parseInt(i32, splitter.next().?, 10);
        // std.debug.print("val: {d}\n", .{value});
        const ballot = splitter.next().?;

        for (ballot) |letter| {
            const index = convert(letter); 
            // std.debug.print("{c} - {d}\n", .{letter,index});
            
            for (prev.items) |previ| {
                // Add to the previous ones that it has this value on this letter
                compareArray[previ*n + index] += value;
                // std.debug.print("added {d} to {d} ({d} + {d})\n", .{value,previ*n + index, previ*n, index});
            }
            try prev.append(index);
        }
        prev.clearAndFree();
    }

    // Will have to build the graph 
    // for A go through until n and check A against i, the one that wins gets the edge
    // then I will have to go through from B until n etc..

    var g: Graph = try Graph.init(allocator, n); 
    defer g.denit();
    for (0..n) |first| {
        for (first..n) |second| {
            if (first == second) continue; // Skip compare against self
            const x = compareArray[first*n + second];
            const y = compareArray[second*n + first];
            // std.debug.print("first:{d}, second: {d}  ({d} - {d})\n", .{first, second, x, y});
            if (x > y) { // If x wins edge from x to y
                try g.addEdge(first, second);
            } else { // other way around
                try g.addEdge(second, first);
            }
        }
    }

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    for (0..n) |check| {
        const win = try g.checkWin(check);
        const let = convertBack(check);
        if (win) {
            try writer.print("{c}: can win\n", .{let});
        }else {
            try writer.print("{c}: can't win\n", .{let});
        }
    }
    try buffered.flush();

    // std.debug.print("{any}\n", .{compareArray});
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

    try parseAndRunCombinedArray(allocator, all_data);

    // std.debug.print("this is res: \n", .{});
    // try printResults(testing);

    buffer[1] = '1';
}
