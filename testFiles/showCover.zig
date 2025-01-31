/// Author: Felix Stenberg
const std = @import("std");

/// A generic interval type parameterized by `T` (e.g., `i64`, `f64`, etc.).
pub fn Interval(comptime T: type) type {
    return struct {
        pub const Self = @This();

        start: T,
        end: T,
        index: usize,

        /// Comparison function for std.mem.sort:
        /// Sort primarily by `start` ascending; if tie, by `end` descending.
        pub fn lessThan(_: void, a: Self, b: Self) bool {
            return a.start < b.start;
        }
    };
}

/// Finds a minimal subset of intervals that covers a interval interval.
/// Returns the indices of intervals used, in the sorted array.
///
/// Complexity: O(n log n) because of the sort.
///
/// Input: 
/// - T is ther numeric type for the interval boundaries (e.g. f64, i64). 
/// - allocator is the pointer on the heap for storing chosen subset.
/// - interval intervall to cover.
/// - interval_array Set of intervalls to cover interval with.
///
/// Output:
/// - Array of indecies into interval_array that cover interval.
pub fn cover(comptime T: type, allocator: std.mem.Allocator, interval: Interval(T).Self, interval_array: []Interval(T).Self) ![]usize {
    const IntervalType = Interval(T).Self;

    // Sort interval_array based on start (ascending) and end (descending)
    std.mem.sort(IntervalType, interval_array, {}, IntervalType.lessThan);

    if (interval.start > interval.end) {
        return &.{};
    }

    // Handle single-point interval
    if (interval.start == interval.end) {
        for (interval_array) |intervals| {
            if (intervals.start > interval.start) break;
            if (intervals.end >= interval.end) {
                const result = try allocator.alloc(usize, 1);
                result[0] = intervals.index;
                return result;
            }
        }
        return &.{};
    }

    var result = std.ArrayList(usize).init(allocator);
    errdefer result.deinit();

    var current_end = interval.start;
    var index: usize = 0;

    while (current_end < interval.end) {
        var best_end = current_end;
        var best_index: ?usize = null;

        // Find the farthest reaching interval starting before or at current_end
        while (index < interval_array.len and interval_array[index].start <= current_end) {
            if (interval_array[index].end > best_end) {
                best_end = interval_array[index].end;
                best_index = interval_array[index].index;
            }
            index += 1;
        }

        if (best_index == null) {
            return &.{};
        }

        try result.append(best_index.?);
        current_end = best_end;

        // Early exit if we've covered the interval
        if (current_end >= interval.end) break;
    }

    return result.toOwnedSlice();
}
