/// Author: Felix Stenberg
///
/// ex. 5.4 = 5 + 1/(2 + (1/2))
/// 
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

fn parseAndRunCombinedArray(allocator: anytype, data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const n1 = try std.fmt.parseInt(usize, splitter.next().?, 10);
    const n2 = try std.fmt.parseInt(usize, splitter.next().?, 10);

    const t = try calc3(n1,  &splitter,allocator);
    // std.debug.print("---\n", .{});
    const t2 = try calc3(n2,  &splitter, allocator);
    // std.debug.print("---\n", .{});    
    // std.debug.print("t: {any}, t2: {any}\n", .{t,t2});
    var addNom:f64 = 0;
    var addDen:f64 = 0;
    var minusNom:f64 = 0;
    var minusDen:f64 = 0;
    var divNom:f64 = 0;
    var divDen:f64 = 0;
    if (t.denom == t2.denom) {
        addNom = (t.nom + t2.nom);
        addDen = (t.denom);
        minusNom = (t.nom - t2.nom);
        minusDen = (t.denom);
        divNom = t.nom;
        divDen = t2.nom;
    }else {
        addNom = (t.nom*t2.denom  + t2.nom*t.denom);
        addDen = (t.denom*t2.denom);
        minusNom = (t.nom*t2.denom  - t2.nom*t.denom);
        minusDen = (t.denom*t2.denom);
        divNom = t.nom * t2.denom;
        divDen = t2.nom * t.denom;
    }
    const multNom = t.nom * t2.nom;
    const multDen = t.denom * t2.denom;

    // std.debug.print("Addition Result (Numerator): {}\n", .{addNom});
    // std.debug.print("Addition Result (Denominator): {}\n", .{addDen});
    // std.debug.print("Subtraction Result (Numerator): {}\n", .{minusNom});
    // std.debug.print("Subtraction Result (Denominator): {}\n", .{minusDen});

    // std.debug.print("Multiplication Result (Numerator): {}\n", .{multNom});
    // std.debug.print("Multiplication Result (Denominator): {}\n", .{multDen});
    // std.debug.print("Division Result (Numerator): {}\n", .{divNom});
    // std.debug.print("Division Result (Denominator): {}\n", .{divDen});
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();   
    try printRes(addNom, addDen, writer);
    try printRes(minusNom, minusDen, writer);
    try printRes(multNom, multDen, writer);
    try printRes(divNom, divDen, writer);
    try buffered.flush();
    // std.debug.print("add: {d}, min: {d}, mult: {d}, div: {d}\n", .{add, minus, mult, div});
}

fn printRes(num: f64, den: f64, writer: anytype) !void {
    var nom = num;
    var denom = den;

    while (denom != 0) {
        const dec = @divFloor(nom, denom);

        try writer.print("{d} ", .{dec});

        const rest = @mod(nom, denom);
        if (rest == 0) {
            break;
        }
        nom = denom;
        denom = rest;
    }
    try writer.print("\n", .{});
}

const Result = struct {
    nom: f64,
    denom: f64,
};

fn calc3(n: usize, splitter: *std.mem.SplitIterator(u8, .any), allocator: anytype) !Result {
    const allR = try allocator.alloc(f64, n);
    // std.debug.print("n: {d}\n", .{n});
    for (0..n) |i| {
        allR[i] = try std.fmt.parseFloat(f64, splitter.next().?);
        // std.debug.print("{d}\n", .{allR[i]});
    }

    if (n == 1) {
        return .{ .nom = allR[0], .denom = 1 };
    }
    
    var i: usize = n-1;
    var acc: f64 = 0;
    var denom: f64 = 1;
    while (i >= 1) : (i -= 1) {
        const prevR = allR[i-1];
        if(i == n-1){
            const r = allR[i];
            acc = prevR * r + 1;
            denom = r;
            // std.debug.print("acc: {d}, de: {d}\n", .{acc,denom});
            continue;
        }
        // std.debug.print("acc: {d} * {d} + {d}\n", .{acc, prevR, denom});
        const oldAcc = acc;
        acc = prevR * acc + denom;
        // std.debug.print("acc: {d}, de: {d}\n", .{acc, denom});
        denom = oldAcc;
    }
    // std.debug.print("{d}, {d}\n", .{acc, denom});
    return .{.nom = acc, .denom = denom};
}
/// So I need to take r * acc + oldDenom

// r + 1/calc
// So instead I should find the common denominator and then just take the upper part upp to that?
// so take r * div / div + div / 2 * div? and then I should accumalated the r part and the demoninator part

///r: 1, div: 2
///r: 1, div: 4 // Here I want to mult the + 1 with  
///r: 5, div: 5

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