/// Author: Felix Stenberg 
const std = @import("std");

pub fn Graph() type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator, 
        nodeValue: []i64, 
        graphStruct: []std.ArrayList(usize), 


        pub fn init(allocator: std.mem.Allocator, size: usize) !Self {
            const graphStruct = try allocator.alloc(std.ArrayList(usize), size);
            for (graphStruct) |*i| {
                i.* = std.ArrayList(usize).init(allocator);
            }

            const nodeValue = try allocator.alloc(i64, size);

            return Self{
                .allocator = allocator,
                .nodeValue = nodeValue,
                .graphStruct = graphStruct,
            };
        }

        pub fn deinit(self: Self) void {
            for (self.graphStruct) |*value| {
                value.deinit();
            }
            self.allocator.free(self.graphStruct);
            self.allocator.free(self.nodeValue);
        }


        pub fn add_node(self: *Self, node: usize, val: i64, edges: std.ArrayList(usize)) !void {
            self.nodeValue[node] = val;
            for (edges.items) |pointer| {
                if (pointer <= 0) {
                    continue;
                }
                try self.graphStruct[node].append(pointer-1);
            }
        }
    };
}


pub fn bfs(
    graph: *Graph(),
    s: usize,
    t: usize,
    visit: []i64,
    queue: *std.ArrayList(usize)
) !bool {
    @memset(visit, -1);

    try queue.append(s);
    visit[s] = 100;

    var front: usize = 0;
    while (front < queue.items.len) : (front += 1) {
        const current = queue.items[front];
        const currLife = visit[current];
        if (current == t) {
            queue.clearRetainingCapacity();
            return true;
        }
        const neighbors = &graph.graphStruct[current];
        for (neighbors.items) |edge| {
            const nextLife = currLife + graph.nodeValue[edge];
            if (nextLife > 0 and nextLife > visit[edge] and nextLife <= 110000) {
                visit[edge] = nextLife;
                try queue.append(edge);
            }
        }
    }

    queue.clearRetainingCapacity();
    return false;
}

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![]u8 {
    return try reader.readToEndAlloc(allocator, std.math.maxInt(usize));
}
pub fn parseAndRunCombined(allocator: std.mem.Allocator, data: []u8) !void {
    var tokens = std.mem.splitAny(u8, data, " \n");
    var tokensList = std.ArrayList([]const u8).init(allocator);
    defer tokensList.deinit();
    while (tokens.next()) |token| {
        if (token.len == 0) continue;
        try tokensList.append(token);
    }
    var ptr: usize = 0;

    var countNodes = try std.fmt.parseInt(usize, tokensList.items[ptr], 10);
    ptr += 1;
    var testG = try Graph().init(allocator, countNodes);
    defer testG.deinit();

    var edgesArr = std.ArrayList(usize).init(allocator);
    defer edgesArr.deinit();

    var visit = try allocator.alloc(i64, countNodes);
    defer allocator.free(visit);

    var queue = std.ArrayList(usize).init(allocator);
    defer queue.deinit();

    var res = std.ArrayList(bool).init(allocator);
    defer res.deinit();

    var i: usize = 0;
    
    while (ptr < tokensList.items.len) {
        const token = tokensList.items[ptr];
        if (i >= countNodes) {
            
            const countNodes2 = try std.fmt.parseInt(i64, token, 10);
            ptr += 1; 
            if (countNodes2 == -1) break;

            const resE = try solve(&testG, 0, countNodes-1 );
            try res.append(resE);
            testG.deinit();
            
            countNodes = @intCast(countNodes2);
            i = 0;
            testG = try Graph().init(allocator, countNodes);
            allocator.free(visit);
            visit = try allocator.alloc(i64, countNodes);
        } else {

            const valNode = try std.fmt.parseInt(i64, token, 10);
            ptr += 1; 
            const nodEdges = try std.fmt.parseInt(usize, tokensList.items[ptr], 10);
            ptr += 1; 
            edgesArr.clearRetainingCapacity();
            for (0..nodEdges) |_| {
                const ed = try std.fmt.parseInt(usize, tokensList.items[ptr], 10);
                try edgesArr.append(ed);
                ptr += 1; 
            }
            try testG.add_node(i, valNode, edgesArr);
            i += 1;
        }
    }


    if (i >= countNodes) {
        const resE = try solve(&testG, 0, countNodes-1 );
        try res.append(resE);
    }

    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();

    for (res.items) |value| {
        if (value) {
            try writer.print("winnable\n", .{});
        } else {
            try writer.print("hopeless\n", .{});
        }
    }
    try buffered.flush();
}


fn bfsReachable(graph: *Graph(), start: usize, reachable: []bool) void {
    var queue = std.ArrayList(usize).init(graph.allocator);
    defer queue.deinit();
    queue.append(start) catch return;
    reachable[start] = true;
    var front: usize = 0;
    while (front < queue.items.len) : (front += 1) {
        const u = queue.items[front];
        for (graph.graphStruct[u].items) |v| {
            if (!reachable[v]) {
                reachable[v] = true;
                queue.append(v) catch break;
            }
        }
    }
}

fn reverseGraph(graph: *Graph()) ![]std.ArrayList(usize) {
    const reversed = try graph.allocator.alloc(std.ArrayList(usize), graph.graphStruct.len);
    for (reversed) |*list| {
        list.* = std.ArrayList(usize).init(graph.allocator);
    }
    for (graph.graphStruct, 0..) |edges, u| {
        for (edges.items) |v| {
            try reversed[v].append(u);
        }
    }
    return reversed;
}


pub fn solve(graph: *Graph(), start: usize, end: usize) !bool {
    const n = graph.graphStruct.len;
    var dist = try graph.allocator.alloc(i64, n);
    defer graph.allocator.free(dist);
    @memset(dist, std.math.minInt(i64));
    dist[start] = 100;

    for (0..n-1) |_| {
        var updated = false;
        for (0..n) |u| {
            if (dist[u] == std.math.minInt(i64)) continue;
            for (graph.graphStruct[u].items) |v| {
                const new_energy = dist[u] + graph.nodeValue[v];
                if (new_energy > 0 and new_energy > dist[v]) {
                    dist[v] = new_energy;
                    updated = true;
                }
            }
        }
        if (!updated) break;
    }

    if (dist[end] > 0) return true;

    const reachableFromStart = try graph.allocator.alloc(bool, n);
    defer graph.allocator.free(reachableFromStart);
    @memset(reachableFromStart, false);
    bfsReachable(graph, start, reachableFromStart);

    const reversed = try reverseGraph(graph);
    defer {
        for (reversed) |*list| list.deinit();
        graph.allocator.free(reversed);
    }

    var canReachEnd = try graph.allocator.alloc(bool, n);
    defer graph.allocator.free(canReachEnd);
    @memset(canReachEnd, false);
    var endQueue = std.ArrayList(usize).init(graph.allocator);
    defer endQueue.deinit();
    endQueue.append(end) catch {};
    canReachEnd[end] = true;
    var ef: usize = 0;
    while (ef < endQueue.items.len) : (ef += 1) {
        const u = endQueue.items[ef];
        for (reversed[u].items) |v| {
            if (!canReachEnd[v]) {
                canReachEnd[v] = true;
                endQueue.append(v) catch break;
            }
        }
    }

    for (0..n) |u| {
        if (dist[u] == std.math.minInt(i64)) continue;
        for (graph.graphStruct[u].items) |v| {
            const new_energy = dist[u] + graph.nodeValue[v];
            if (new_energy > 0 and new_energy > dist[v] and reachableFromStart[u] and canReachEnd[v]) {
                return true;
            }
        }
    }

    return false;
}




pub fn main() !void {
    const stdin = std.io.getStdIn();
    const allocator = std.heap.page_allocator;

    const all_data = try readInput(
        allocator,
        stdin,
    );
    defer allocator.free(all_data);

    try parseAndRunCombined(allocator,all_data);

}
