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

fn parseAndRunCombinedArray(allocator: std.mem.Allocator, data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const N = try std.fmt.parseInt(usize, splitter.next().?, 10);
    _ = try std.fmt.parseInt(usize, splitter.next().?, 10);

    var nodes = try allocator.alloc(std.ArrayList(usize), N);
    defer allocator.free(nodes);
    for (nodes,0..) |_, i| {
        nodes[i] = std.ArrayList(usize).init(allocator);
    }

    while (splitter.next()) |token| {
        if (std.mem.eql(u8,token, "")) {
            continue;
        }
        const K = try std.fmt.parseInt(usize, token, 10);
        const L = try std.fmt.parseInt(usize, splitter.next().?, 10);
        std.debug.print("{d},{d}\n", .{K,L});
        try nodes[K].append(L);
        try nodes[L].append(K);
        
    }
    const memo = try allocator.alloc(f64, N);
    defer allocator.free(memo);
    @memset(memo, -1);
    const visit = try allocator.alloc(bool, N);
    defer allocator.free(visit);
    @memset(visit, false);

    //BFS to find expected length first
    var queue = std.TailQueue(usize){};
    const node1 = try allocator.create(std.TailQueue(usize).Node);
    node1.data = N-1;
    queue.append(node1);
    var layer: f64 = 2;
    const cacl1 = try allocator.alloc(f64, N);
    defer allocator.free(cacl1);
    @memset(cacl1, 0);

    // const lenth: f64 = @floatFromInt(nodes[N-1].items.len);
    // memo[N-1] = 1 * 1/lenth;
    memo[N-1] = 0;

    while (queue.len != 0) {
        const cur = queue.popFirst().?.data; 
        if(visit[cur] == true) continue;
        visit[cur] = true;

        const neibours = nodes[cur].items;
        std.debug.print("Curr node: {d}, neigbours: {any}\n", .{cur, neibours});
        for (neibours) |value| {
            if (memo[value] == -1) {
                const len2: f64 = @floatFromInt(nodes[value].items.len);
                memo[value] = layer * (len2-1)/len2;
                std.debug.print("node {d}, weight: {d}, len {d} \n", .{value, memo[value], len2});

                cacl1[cur] += memo[value];
            } else {
                std.debug.print("node {d}, weight: {d} \n", .{value, memo[value]});
                cacl1[cur] += memo[value];
            }
            
            std.debug.print("new calc = {d}\n", .{cacl1[cur]});

            const neNode = try allocator.create(std.TailQueue(usize).Node);
            neNode.data = value;
            queue.append(neNode);
        }
        std.debug.print("----\n", .{});

        layer += 1;
    }
    std.debug.print("calc1: {any}\n", .{cacl1 });
    var r: f64 = 0;
    for (cacl1, 0..) |value, i| {
        std.debug.print("sum of {d}'s neigbours is {d}\n", .{i,value});
        r += value;
    }
    const endfloat: f64 = @floatFromInt(N-1);
    std.debug.print("r: {d}\n", .{r/endfloat});
    // const te = try goThrough(nodes, N-1, visited, 0);

    std.debug.print("memo: {any}\n", .{memo});

    // std.debug.print("{d}\n", .{te});
}

// Should actually use a BFS
// fn goThrough(fullList: []std.ArrayList(usize), next: usize, prevCalc: f64, memo: []f64) !f64 {
//     //Base case I get to a node I've already been to during this specific path walk
//     if (memo[next] != -1) {
//         return memo[next];
//     }

//     // for (fullList[next].items) |value| {
//     // }


//     // const len = @floatFromInt(fullList[next].items.len);
    
//     return 1 + 1 / len;
// }




// 0 1 1 2 
// 0 2
// I guess we can count how many paths in total


// Each time there is a 50% chance that he takes the path that gets him closer
// So we get something like always start with 1, then get something like 
// Count length of road,
// for example ((0.5 * 1) + (0.5 * 1)) + ((0.5 * 1) + (0.5 * 1))
// 
// Walk backwards, if at exit, expected is 0
// if walk back one from exit expected is 1 * 1 / divided by degree for each path going back from exit
// so for example on first ex
// at 2 we have 0
// then we have ((0.5 * 1) + (0.5 * 1)) + ((0.5 * 1) + (0.5 * 1))

// ex 2
// (1 * (1/3) + (2 * 0.5 + 2* (1/3) + 0.5 * 1) + (2*(1/3) + (2 * 0.5) + 0.5 * 1)) + (0.5 * 1 + (1/3)*2 + 0.5 * 2 + (1/3) * 1)
// Can be done reqursively if we have build the graph 
// Can build graph either with struct nodes or as an array with each index as the node and then an list with the edge nodes
// And then just mark what nodes have been visited so we don't count them again for the path we are going down




// 3 + 2 + 2 

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