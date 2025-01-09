const std = @import("std");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;


fn readLineToVariable(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
    return line orelse null; // Handle the case where no more lines are available
}

fn readCharEndSpace(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, ' ');
    return line orelse null; // Handle the case where no more lines are available
}

fn convertfuckingstringtoint(input: ?[]const u8) !i32 {
    var ret: i32 = 0;
    if (input) |value| {
        const trimshit = std.mem.trim(u8, value, " \n\r");
        ret = try std.fmt.parseInt(i32, trimshit, 10);
        //std.debug.print("converted: {d}\n", .{ret});
        return ret;
    }
    return 0;
}

fn spacedStringToInt(input: std.ArrayList(u8), allocator: anytype) std.ArrayList([]i32) {
    var res = std.ArrayList([]i32).init(allocator);
    for (input.items) |c| {
        
    }
}

fn stringToInt() !void {

}

fn readFullInput(allocator: anytype, stdin: anytype) !std.ArrayList(u8) {
    var buffer: [100]u8 = undefined;

    // Read each line and store it in the lines array
    var input = try readLineToVariable(stdin.reader(), buffer[0..]);
    //Either re alloc every time new mem or use a arraylist or what its called
    var fullString = std.ArrayList(u8).init(allocator);
    while (true) {
        if (input)|real| {
            try fullString.appendSlice(real);
            try fullString.append('\n');
        }else { break; }
        input = try readLineToVariable(stdin.reader(), buffer[0..]);
    }

    return fullString;
}

fn readFullInputArrays(allocator: anytype, stdin: anytype) !std.ArrayList(u8) {
    var buffer: [100]u8 = undefined;

    // Read each line and store it in the lines array
    var input = try readLineToVariable(stdin.reader(), buffer[0..]);
    //Either re alloc every time new mem or use a arraylist or what its called
    var fullString = std.ArrayList([]u8).init(allocator);
    while (true) {
        if (input)|real| {
            try fullString.appendSlice(real);
            try fullString.append('\n');
        }else { break; }
        input = try readLineToVariable(stdin.reader(), buffer[0..]);
    }

    return fullString;
}

pub fn main() !void {
    const stdin = std.io.getStdIn();

    const allocator = std.heap.page_allocator;

    const input = try readFullInput(allocator, stdin);

    for (input.items) |c| {
        std.debug.print("{c}", .{c});
    }
}


