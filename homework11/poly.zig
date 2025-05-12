// Author: Felix Stenberg and Viktor Widin

const std = @import("std");


pub const point = struct {x: f64, y: f64};

fn lessPointsY(_: void, a: point, b: point) bool {
    return a.y < b.y or (a.y == b.y and a.x < b.x);
}

fn crossProuctTwoPoints(x1: f64, y1: f64, x2: f64, y2: f64) f64 {
    return (x1 * y2) - (y1 * x2);
}

fn crossForSumPolyArea(p0: point, p1: point, p2: point) f64 {
    return crossProuctTwoPoints((p1.x-p0.x), (p1.y-p0.y), (p2.x - p0.x),(p2.y-p0.y));
}

pub fn polygon_area(points: []point) f64{
    var sum: f64 = 0;
    const p0 = points[0];
    for (1..points.len-1) |index| {
        sum += crossForSumPolyArea(p0, points[index], points[index+1]);
    }
    return sum/2;
}

const polarPoint = struct {index: usize, angle: f64, distSq: f64};

fn lessPolarPoints(_: void, a: polarPoint, b: polarPoint) bool {
    if (a.angle != b.angle) {
        return a.angle < b.angle;
    } else {
        return a.distSq < b.distSq;
    }
}

pub fn Convex_Hull(points: []point, allocator: std.mem.Allocator) ![]point{

    std.mem.sort(point, points, {}, lessPointsY);

    var unique = std.ArrayList(point).init(allocator);
    defer unique.deinit();
    try unique.append(points[0]);
    for (points[1..]) |p| {
        const last = unique.items[unique.items.len - 1];
        if (!(p.x == last.x and p.y == last.y)) {
            try unique.append(p);
        }
    }

    if (unique.items.len == 1) {
        return try allocator.dupe(point, &[_]point{unique.items[0]});
    }
    if (unique.items.len == 2) {
        if (unique.items[0].x == unique.items[1].x and unique.items[0].y == unique.items[1].y) {
            return try allocator.dupe(point, &[_]point{unique.items[0]});
        } else {
            return try allocator.dupe(point, unique.items);
        }
    }

    const leftMostP = unique.items[0];

    const polarPointsRelativeLeftMostP = try allocator.alloc(polarPoint, unique.items.len-1);
    defer allocator.free(polarPointsRelativeLeftMostP);
    
    for (1..unique.items.len) |i| {
        polarPointsRelativeLeftMostP[i-1] = .{
            .index = i,
            .angle = angleRelativeToP1(leftMostP, unique.items[i]),
            .distSq = dist_sq(leftMostP, unique.items[i])
        };
    }
    
    std.mem.sort(polarPoint, polarPointsRelativeLeftMostP, {}, lessPolarPoints);

    var stack = std.ArrayList(point).init(allocator);
    defer stack.deinit();

    try stack.append(leftMostP);
    try stack.append(unique.items[polarPointsRelativeLeftMostP[0].index]);

    for (1..polarPointsRelativeLeftMostP.len) |i| {
        const third = unique.items[polarPointsRelativeLeftMostP[i].index];
        while (true) {
            if (stack.items.len < 2) break;
            const first = stack.items[stack.items.len - 2];
            const second = stack.items[stack.items.len - 1];
            const cross = crossForSumPolyArea(first, second, third);
            if (cross > 0) {
                break;
            } else {
                _ = stack.pop();
            }
        }
        try stack.append(third);
    }

    return stack.toOwnedSlice();
}


// p0 -> p1, p1 -> p2
fn angleThreePoints(p0:point, p1:point, p2:point) f64 {
    const angle1 = angleRelativeToP1(p0, p1);
    const angle2 = angleRelativeToP1(p1, p2);

    var diff = angle2 - angle1;
    while (diff <= -std.math.pi) {
        diff += 2.0 * std.math.pi;
    }
    while (diff > std.math.pi) {
        diff -= 2.0 * std.math.pi;
    }
    return diff;
}



fn angleRelativeToP1(p1: point, p2: point) f64 {
    return std.math.atan2(p2.y-p1.y, p2.x-p1.x);
}

fn dist_sq(p1: point, p2: point) f64{
    return std.math.pow(f64,(p2.x-p1.x),2) + std.math.pow(f64,(p2.y-p1.y),2);
}

