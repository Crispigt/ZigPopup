/// Author: Felix Stenberg
///
///
/// so we can get c by taking
///
/// c = 1/((v/s)-1)
///
/// We can then calc
///
/// n(lg(n))^{c*sqrt(2)}
/// / p*10^9
/// maybe problems taking p < 0 * 10^9
/// prob gonna be some weird floating point things
///
/// need to find when these go together, miss understood.
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
fn parseAndRunCombinedArray(data: []u8) !void {
    var splitter = std.mem.splitAny(u8, data, " \n");

    const n = try std.fmt.parseFloat(f64, splitter.next().?);
    const p = try std.fmt.parseFloat(f64, splitter.next().?);
    const s = try std.fmt.parseFloat(f64, splitter.next().?);
    const v = try std.fmt.parseFloat(f64, splitter.next().?);

    // std.debug.print("{any}, {any}, {any}, {any}\n", .{ n, p, s, v });


    var resC: f64 = 0;
    const maxIter: i32 = 10000;
    var iter: i32 = 0;

    // Newton-Raphson variables
    var x: f64 = 100.0;
    const tol: f64 = 1e-6;
    const e: f64 = 0.001; 
    var oldx: f64 = x;

    while (iter <= maxIter) : (iter += 1) {
        const t_plus = calcT(x + e, n, p, s, v);
        const t_minus = calcT(x - e, n, p, s, v);
        const current_t = calcT(x, n, p, s, v);

        
        const f = (t_plus - t_minus) / (2.0 * e);
        
        const f_prime = (t_plus - 2.0 * current_t + t_minus) / (e * e);

        if (@abs(f_prime) < 1e-10) {// No zero division
            break;
        }

        oldx = x;
        x = x - f / f_prime;

        // Check for convergence
        if (@abs(x - oldx) <= tol) {
            break;
        }
    }

    resC = x;
    const resT = calcT(resC, n, p, s, v);
    var stdout = std.io.getStdOut();
    var buffered = std.io.bufferedWriter(stdout.writer());
    const writer = buffered.writer();
    try writer.print("{d} {d}\n", .{resT,resC});
    try buffered.flush();
    // std.debug.print("t2:{d}, c: {d}\n", .{ resT, resC });
    // std.debug.print("actual t:{d}, actual c: {d}\n", .{ t, actualC });

    // const diff = @abs(resC - actualC);
    // if (diff < tol) {
    //     std.debug.print("resC is within 1e-6 of the actualC\n", .{});
    // } else {
    //     std.debug.print("resC is NOT within 1e-6 of the actualC. Diff={}\n", .{diff});
    // }


}

fn calcT(c: f64, n: f64, p: f64, s: f64, v: f64) f64 {
    const innerMira: f64 = 1 + 1 / c;
    const vs = s / v;
    const mira = vs * innerMira;
    // std.debug.print("mira: {d}\n", .{mira});

    const csqrttwo: f64 = c * std.math.sqrt2;
    const logn: f64 = std.math.log2(n);
    const roof: f64 = std.math.pow(f64, logn, csqrttwo);
    // std.debug.print("roof: {d}\n", .{roof});
    const roofn: f64 = n * roof;
    // std.debug.print("roofn: {d}\n", .{roofn});

    const ten: f64 = 10;
    const nine: f64 = 9;
    const pten: f64 = p * std.math.pow(f64, ten, nine);

    const arora: f64 = roofn / pten;

    const t = arora + mira;
    return t;
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

    try parseAndRunCombinedArray(all_data);

    // std.debug.print("this is res: \n", .{});
    // try printResults(testing);

    buffer[1] = '1';
}
