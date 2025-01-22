///
/// Author: Felix Stenberg
/// 
/// Seems like we have to compare each of the words to the word on the earlier line
/// we then store this word for that var, if we come to the same var
/// and we check above word and it is wrong the thing doesn't work
/// Need to check both way because the var can be different for both ways
///
/// Transpose each var with words and check against other if we can match them
///
///
/// we can map each word to specific location in array so 1 goes to one, makes it easier to comapare what is there
///
///
const std = @import("std");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;

/// Reads a single line (until `\n`) from `reader` into `buffer`.
/// Returns the slice of data if successful or `null` if EOF is reached.
///
/// - Parameters:
///   - `reader`: the stream from which to read
///   - `buffer`: a temporary buffer for reading
///
/// - Returns: `?[]u8` representing the line read, or `null` if no line was read
fn readLineToVariable(reader: anytype, buffer: []u8) !?[]u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
    return line orelse null;
}

/// Reads a single token from `reader` until a space (' ') delimiter is found or EOF.
/// Returns the slice of data if successful or `null` if EOF is reached.
///
/// - Parameters:
///   - `reader`: the stream from which to read
///   - `buffer`: a temporary buffer for reading
///
/// - Returns: `?[]const u8` representing the token read, or `null` if no token was read
fn readCharEndSpace(reader: anytype, buffer: []u8) !?[]const u8 {
    const line = try reader.readUntilDelimiterOrEof(buffer, ' ');
    return line orelse null; // Handle the case where no more lines are available
}

/// Converts a `?[]const u8` string (if present) to an `i32`.
/// Returns `0` if the input is `null`.
///
/// - Parameters:
///   - `input`: an optional slice of bytes containing the numeric string
///
/// - Returns: `i32` parsed from the string, or `0` if input is `null`
///
/// - Throws: any error resulting from `std.fmt.parseInt` if parsing fails
fn convertfuckingstringtoint(input: ?[]const u8) !i32 {
    var ret: i32 = 0;
    if (input) |value| {
        const trimshit = std.mem.trim(u8, value, " \n\r");
        ret = try std.fmt.parseInt(i32, trimshit, 10);
        return ret;
    }
    return 0;
}

/// Splits multiple input lines by the specified `delimiter` and parses each token into `i32`.
/// For each line in `input`, it will:
///   1. Split the line into tokens (using `delimiter`).
///   2. Parse each token as `i32`.
///   3. Store each line's integer tokens in a separate slice.
///
/// - Parameters:
///   - `input`: a list of byte slices, each element being one line (e.g. ["123,456", "789,10"])
///   - `delimiter`: the delimiter that may consist of multiple bytes (e.g. ",")
///   - `allocator`: an allocator to manage memory for the resulting array
///
/// - Returns: a `std.ArrayList([]i32)`, where each element corresponds to a line's parsed integers
///
/// - Throws: any errors from allocation or integer parsing
pub fn delimiterStringToInt(
    input: std.ArrayList([]u8),
    delimiter: []const u8,
    allocator: anytype,
) !std.ArrayList([]i32) {
    var result = std.ArrayList([]i32).init(allocator);

    for (input.items) |line| {
        // Split the line into tokens.
        var tokens = try splitByDelimiter(line, delimiter, allocator);

        // Parse each token into i32.
        var numbers = std.ArrayList(i32).init(allocator);
        for (tokens.items) |token| {
            if (token.len == 0) continue;
            const parsed = try std.fmt.parseInt(i32, token, 10);
            try numbers.append(parsed);
        }

        // Turn our dynamic list of i32 into an owned slice, then store it in the final result.
        const owned_slice: []i32 = try numbers.toOwnedSlice();
        try result.append(owned_slice);

        numbers.deinit();
        tokens.deinit();
    }

    return result;
}

/// Splits `line` into tokens, using a multi-byte `delimiter`.
/// Returns a list of slices pointing to the original memory (no extra copy).
///
/// - Parameters:
///   - `line`: the byte slice to split
///   - `delimiter`: the multi-byte delimiter
///   - `allocator`: the allocator to use for creating the tokens list
///
/// - Returns: `std.ArrayList([]u8)` whose items are slices of `line`
///
/// - Throws: any error from the allocator
pub fn splitByDelimiter(
    line: []u8,
    delimiter: []const u8,
    allocator: anytype,
) !std.ArrayList([]u8) {
    var tokens = std.ArrayList([]u8).init(allocator);
    var start: usize = 0;
    var i: usize = 0;

    while (i < line.len) {
        if (i + delimiter.len <= line.len and
            std.mem.eql(u8, line[i .. i + delimiter.len], delimiter))
        {
            // We found the delimiter:
            // everything from `start` up to `i` is a token.
            try tokens.append(line[start..i]);

            // Skip over the delimiter and set up the new token start.
            i += delimiter.len;
            start = i;
        } else {
            i += 1;
        }
    }

    // Capture the final token (if any characters remain after the last delimiter).
    if (start < line.len) {
        try tokens.append(line[start..line.len]);
    }

    return tokens;
}

/// Reads the entire input (line by line) from `stdin`,
/// appends it to a single `std.ArrayList(u8)`, and returns it.
///
/// - Parameters:
///   - `allocator`: the allocator used for creating the output buffer
///   - `stdin`: the standard input stream
///   - `buffer`: a temporary buffer used for reading chunks
///
/// - Returns: `std.ArrayList(u8)` containing all the read data (with `\n` separating lines)
///
/// - Throws: any error from reading the stream or appending data
pub fn readFullInput(allocator: anytype, stdin: anytype, buffer: []u8) !std.ArrayList(u8) {
    var input = try readLineToVariable(stdin.reader(), buffer[0..]);
    var fullString = std.ArrayList(u8).init(allocator);
    while (true) {
        if (input) |real| {
            try fullString.appendSlice(real);
            try fullString.append('\n');
        } else {
            break;
        }
        input = try readLineToVariable(stdin.reader(), buffer[0..]);
    }

    return fullString;
}

/// Reads the entire input (line by line) from `reader`,
/// storing each full line as its own allocated slice in `std.ArrayList([]u8)`.
///
/// - Parameters:
///   - `allocator`: the allocator used for each line read
///   - `reader`: the stream from which to read
///   - `buffer`: a temporary buffer for reading lines
///
/// - Returns: `std.ArrayList([]u8)` where each item is a separately allocated line
///
/// - Throws: any error from reading the stream or allocating memory
pub fn readFullInputArrays(allocator: anytype, reader: anytype, buffer: []u8) !std.ArrayList([]u8) {
    var lines = std.ArrayList([]u8).init(allocator);
    var input = try readLineToVariable(reader, buffer[0..]);

    while (input) |line| {
        const temp = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, temp, line);
        try lines.append(temp);
        input = try readLineToVariable(reader, buffer[0..]);
    }

    return lines;
}



// fn delimiterStringToInt(input: std.ArrayList([]u8), delimiter: u8, allocator: anytype) std.ArrayList([]i32) {
//     var res = std.ArrayList([]i32).init(allocator);
//     var resInt: i32 = 0;
//     for (input.items) |lines| {
//         const linesTrim = std.mem.trim(u8, lines, delimiter);
//         // If something between each number then it will be the len divided by the len of the delimiter - 1 right?
//         var temp = try allocator.alloc(i32, (linesTrim.len / delimiter.len));
//         var count: usize = 0;
//         var sizeNum: usize = 0;
//         var startNum: usize = 0;

//         for (linesTrim) |value| {
//             if (value != delimiter) {
//                 sizeNum +=1;
//             }else {
//                 resInt = try std.fmt.parseInt(i32, linesTrim[startNum..sizeNum], 10);
//                 temp[count] = resInt;
//                 count += 1;
//                 sizeNum = 0;
//             }
//             startNum += 1;
//         }
//         try res.append(temp);
//     }
//     return res;
// }


pub fn helpMeSolve(line1: []u8, line2: []u8, allocator: anytype) ![]const u8 {

    var res = std.ArrayList(u8).init(allocator);
    //var resArray = std.ArrayList([]u8).init(allocator);
    var res2 = std.ArrayList(u8).init(allocator);
    // var res2 = std.ArrayList(u8).init(allocator); 

    // var resArr1 = std.ArrayList([]u8).init(allocator);
    // var resArr2 = std.ArrayList([]u8).init(allocator);


    const line1split = try splitByDelimiter(line1, " ", allocator);
    const line2split = try splitByDelimiter(line2, " ", allocator);
    defer line1split.deinit();
    defer line2split.deinit();


    var line1Hashmap =  std.HashMap([]const u8, usize, std.hash_map.StringContext, 99).init(allocator);
    var line2Hashmap =  std.HashMap([]const u8, usize, std.hash_map.StringContext, 99).init(allocator);
    var mixedHashmap1 =  std.HashMap([]const u8, []const u8, std.hash_map.StringContext, 99).init(allocator);
    var mixedHashmap2 =  std.HashMap([]const u8, []const u8, std.hash_map.StringContext, 99).init(allocator);
    defer mixedHashmap1.deinit();
    defer mixedHashmap2.deinit();
    defer line1Hashmap.deinit();
    defer line2Hashmap.deinit();


    var count: usize = 0;
    for (line1split.items) |value| {
        // std.debug.print("{s} ", .{value});
        if (value[0] == '<') {
            const variable = line1Hashmap.get(value);
            const aboveLine = line2split.items[count]; 
            if(variable)| variable1|{
                // std.debug.print("1Var exists: {s} : {s}\n", .{line1split.items[variable1], aboveLine});
                if (std.mem.eql(u8, line2split.items[variable1], aboveLine)) {
                    // std.debug.print("1problem solve", .{});
                
                }else {
                    // std.debug.print("1got it \n", .{});
                    return "-";
                }
            }else {
                // std.debug.print("1test, added {s} : {d} \n ", .{value, count});
                // Will create problem where line has a word with <>
                if (aboveLine[0] == '<') {
                    std.debug.print("1worked for {s}\n", .{value});
                    try res.appendSlice(aboveLine[0..]);
                    try res.append(' ');
                    count +=1;
                    continue;
                } else{
                    try line1Hashmap.put(@as([]const u8, value), count);
                    try res.appendSlice(aboveLine[0..]);
                    try res.append(' ');
                    count +=1;
                    continue;
                }
            }
        }
        std.debug.print("does this run everytime?", .{});
        try res.appendSlice(value[0..]);
        try res.append(' ');        
        count +=1;
    }




    count = 0;
    for (line2split.items) |value| {
        // std.debug.print("{s} ", .{value});
        if (value[0] == '<') {
            const variable = line2Hashmap.get(value);
            const aboveLine = line1split.items[count]; 
            if(variable)| variable1|{
                // std.debug.print("2Var exists: {s} : {s}\n", .{line1split.items[variable1], aboveLine});
                if (std.mem.eql(u8, line1split.items[variable1], aboveLine)) {
                    // std.debug.print("problem solve", .{});
                } else {
                    // std.debug.print("2got it \n", .{});
                    return "-";
                }

            }else {
                // std.debug.print("2test, added {s} : {d} \n ", .{value, count});
                if (aboveLine[0] == '<') {
                    std.debug.print("2worked\n", .{});
                    const valueAtKeyLine1 = line1Hashmap.get(aboveLine);
                    //std.debug.print("pointing to: {s}\n", .{aboveLine});
                    if (valueAtKeyLine1)|valueAtKeyLine1worked| {
                        const wordThatAboveVariableHolds = line2split.items[valueAtKeyLine1worked];
                        std.debug.print("pointing to: {s}\n", .{wordThatAboveVariableHolds});
                        std.debug.print("here if there was variable: {s}\n", .{wordThatAboveVariableHolds});
                        
                        try mixedHashmap1.put(aboveLine,wordThatAboveVariableHolds);
                        try mixedHashmap2.put(value, wordThatAboveVariableHolds);

                        try res2.appendSlice(value);
                        try res2.append(' ');
                        count +=1;
                        continue;
                    }
                    try res2.appendSlice(aboveLine[0..]);
                    try res2.append(' ');
                    count +=1;
                    continue;
                }else{
                    try line2Hashmap.put(@as([]const u8, value), count);
                    try res2.appendSlice(aboveLine[0..]);
                    try res2.append(' ');
                    count +=1;
                    continue;
                }
            }
        }
        try res2.appendSlice(value[0..]);
        try res2.append(' ');
        count +=1;
    }




    const result = try res.toOwnedSlice();
    const result2 =  try res2.toOwnedSlice();
    std.debug.print("restult1: {s}, results2: {s}\n", .{result, result2});

    


    if (std.mem.eql(u8,result,result2)) {
        return result;
    }
    return "-";
}

const list= std.ArrayList;

pub fn solveAll(input: std.ArrayList([]u8), allocator: anytype) !std.ArrayList([]const u8) {
    var res = std.ArrayList([]const u8).init(allocator);
    const inputArray = input.items;
    const amount: i32 = try std.fmt.parseInt(i32, inputArray[0], 10);
    if(amount == 0){
        try res.append("");
        return res;
    }
    var ac: usize = 1;
    // std.debug.print("{d}\n", .{amount});
    for(1..@intCast(amount+1))|i|{
        ac = i*2-1;
        // std.debug.print("ac: {d}\n", .{ac});
        // std.debug.print("line 1: {s}, line 2: {s} \n", .{inputArray[ac], inputArray[ac+1]});
        const line = try helpMeSolve2(inputArray[ac], inputArray[ac + 1], allocator);  
        try res.append(line);
    }
    return res;
}


const Node = struct {
    value: []u8,
    word: []u8,
    nodeList: std.ArrayList([]u8),

    pub fn init(allocator: anytype) !Node {
        return Node{
            .value = &[_]u8{}, 
            .word = &[_]u8{},
            .nodeList =  std.ArrayList([]u8).init(allocator),
        };
    }
    pub fn deinit(self: *Node) void {
        self.nodeList.deinit();
    }
};


// If <> then check if on the other side there is <> 
// if not <> then add the word to the node and to the hash map to be able to check
// if <> then add the <> to the mapping of the node, this will end up happening for both sides
// so we add to hashmap for each to be able to retrieve node quickly
// 
// If we find a variable and we have a <node> in the hash map we replace that and look at all of it's neighbours
// and replace theirs with 




pub fn helpMeSolve2(line1: []u8, line2: []u8, allocator: anytype) ![]const u8 {

    var res = std.ArrayList(u8).init(allocator);
    defer res.deinit();
    //var resArray = std.ArrayList([]u8).init(allocator);
    var res2 = std.ArrayList(u8).init(allocator);
    defer res2.deinit();
    // var resArr1 = std.ArrayList([]u8).init(allocator);
    // var resArr2 = std.ArrayList([]u8).init(allocator);


    const line1split = try splitByDelimiter(line1, " ", allocator);
    const line2split = try splitByDelimiter(line2, " ", allocator);
    defer line1split.deinit();
    defer line2split.deinit();



    var mixedHashmap1 =  std.HashMap([]const u8, *Node, std.hash_map.StringContext, 80).init(allocator);
    var mixedHashmap2 =  std.HashMap([]const u8, *Node, std.hash_map.StringContext, 80).init(allocator);
    defer mixedHashmap1.deinit();
    defer mixedHashmap2.deinit();
    // defer line1Hashmap.deinit();
    // defer line2Hashmap.deinit();


    var count: usize = 0;
    for (line1split.items) |wordOnLine1| {//Get all words

        std.debug.print("--- Map 1---\n", .{});
        var it = mixedHashmap1.iterator();
        while (it.next()) |entry| {
            std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
        }

        std.debug.print("--- Map 2---\n", .{});
        it = mixedHashmap2.iterator();
        while (it.next()) |entry| {
            std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
        }



        std.debug.print("----We are on count{d}----\n", .{count});
        const aboveLine = line2split.items[count]; // Word on other line
        if (wordOnLine1[0] == '<') { // We have a variable
            const node = mixedHashmap1.get(wordOnLine1);
            if(node)| node1|{// We have a node already present for this variable

                if (aboveLine[0] == '<') { // Other line has a variable
                    //Check if there is a word in that node
                    const aboveNode = mixedHashmap2.get(aboveLine);
                    if(aboveNode)|aboveNode1|{// Node exists on the other side
                        // We need to check if this node has a reference to node1 otherwise add one
                        // and we need to check if it has a word in word no need to since it will auto propagate

                        if(checkForReferense(aboveNode1, wordOnLine1)){// We add reference
                            try aboveNode1.nodeList.append(wordOnLine1);
                        }
                    }else{ // No node was present so we set up a new one and add referense to node one
                        var newAboveNode = try Node.init(allocator);
                        newAboveNode.value = aboveLine;
                        std.debug.print("New node on line 2 value:{s} \n", .{newAboveNode.value});
                        try newAboveNode.nodeList.append(wordOnLine1); 
                        try mixedHashmap2.put(@as([]const u8, aboveLine), &newAboveNode);
                        std.debug.print("put: {s} map2, val {s}\n", .{aboveLine,newAboveNode.value});

                    }
                    count +=1;
                    continue;
                } else{
                    // This means we have a value above so we have to first check if value exits in node1
                    // other wise add to node1 and propagate to neighbours
                    std.debug.print("node1s value {s}\n", .{node1.value});
                    if (node1.word.len != 0) {
                        if (std.mem.eql(u8, node1.word, aboveLine)) {
                            //No problem word is according to pattern
                        }else {
                            // std.debug.print("1got it \n", .{});
                            return "-";
                        }
                    }
                    std.debug.print("We propagate from line 1\n", .{});
                    node1.word = aboveLine;
                    try propagateWord(node1, aboveLine, mixedHashmap2, mixedHashmap1);

                    count +=1;
                    continue;
                }

            } else { // We have no node present for this variable
                // Will create problem where line has a word with <>
                var newNode = try Node.init(allocator); // Create new node
                std.debug.print("New node beore on line1 value:{s} \n", .{newNode.value});

                std.debug.print("--- Map 1 before change value---\n", .{});
                var it2 = mixedHashmap1.iterator();
                while (it2.next()) |entry| {
                    std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
                }

                newNode.value = wordOnLine1;


                std.debug.print("--- Map 1 change value---\n", .{});
                it2 = mixedHashmap1.iterator();
                while (it2.next()) |entry| {
                    std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
                }
                std.debug.print("New node on line1 value:{s} \n", .{newNode.value});


                if (aboveLine[0] == '<') { // Check if word on line 2
                    const aboveNode = mixedHashmap2.get(aboveLine);
                    if(aboveNode)|aboveNode1|{ // Node for this variable exists
                        try aboveNode1.nodeList.append(wordOnLine1);
                        try newNode.nodeList.append(aboveLine);
                        newNode.word = aboveNode1.word;
                    }else{
                        var newAboveNode = try Node.init(allocator);
                        newAboveNode.value = aboveLine;
                        std.debug.print("New node for both lines:{s} \n", .{newAboveNode.value});
                        try newAboveNode.nodeList.append(wordOnLine1);
                        std.debug.print("put: {s} map2, val {s}\n", .{aboveLine,newAboveNode.value});
                        try mixedHashmap2.put(@as([]const u8, aboveLine), &newAboveNode);
                        const tes = mixedHashmap2.get(aboveLine);
                        if (tes)|tes1| {
                            std.debug.print("Does this go through? {s}\n", .{tes1.value});
                        } else {
                            std.debug.print("problem\n", .{});
                        }
                    }
                    std.debug.print("put: {s} map1, val {s}\n", .{wordOnLine1,newNode.value});
                    try mixedHashmap1.put(@as([]const u8, wordOnLine1), &newNode);
                    count +=1;
                    continue;
                } else{// There is a word on line 2

                    newNode.word = aboveLine;
                    //Do I need to propogate this? If it is a newnode shouldn't have a neighbour list
                    //try propagateWord(&newNode, aboveLine, mixedHashmap2, mixedHashmap1);
                    std.debug.print("put: {s} map1, val {s}\n", .{wordOnLine1,newNode.value});
                    
                    std.debug.print("--- Map 1 before put---\n", .{});
                    it2 = mixedHashmap1.iterator();
                    while (it2.next()) |entry| {
                        std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
                    }
                    
                    try mixedHashmap1.put(@as([]const u8, wordOnLine1), &newNode);
                    
                    std.debug.print("--- Map 1 here---\n", .{});
                    it2 = mixedHashmap1.iterator();
                    while (it2.next()) |entry| {
                        std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
                    }
                    
                    count +=1;
                    continue;
                }
            }
        }else{//We have no variable on current line
            if (aboveLine[0] == '<') {// we have variable on other side
                //we need to check if it has been initalised 
                //and if it has a word that matches otherwise add and propagate
                const aboveNode = mixedHashmap2.get(aboveLine);
                if(aboveNode)|aboveNode1|{ // Node for this variable exists
                    if (aboveNode1.word.len != 0) {// Has word?
                        if (std.mem.eql(u8, wordOnLine1, aboveNode1.word)) {
                            //No problem word is according to pattern
                        }else {
                            // std.debug.print("1got it \n", .{});
                            return "-";
                        }
                    } else{ // Otherwise add word
                        std.debug.print("We propagate from line 2\n", .{});
                        aboveNode1.word = wordOnLine1;
                        std.debug.print("Neiboughrs: ", .{});
                        for(aboveNode1.nodeList.items)|items|{
                            std.debug.print("{s} ", .{items});
                        }
                        std.debug.print("\n", .{});
                        try propagateWord(aboveNode1, wordOnLine1, mixedHashmap1, mixedHashmap2);
                    }
                }else{
                    var newAboveNode = try Node.init(allocator);
                    newAboveNode.word = wordOnLine1;
                    newAboveNode.value = aboveLine;
                    std.debug.print("New node for line 2, word on line 1 value: {s} \n", .{newAboveNode.value});
                    //Same here shouldn't have to propagate
                    // try propagateWord(&newAboveNode, value, mixedHashmap1, mixedHashmap2);
                    std.debug.print("put: {s} map2, val {s}\n", .{aboveLine,newAboveNode.value});

                    try mixedHashmap2.put(@as([]const u8, aboveLine), &newAboveNode);
                }                


            }else {
                if (std.mem.eql(u8, wordOnLine1, aboveLine)) {
                    //No problem word is according to pattern
                }else {
                    //std.debug.print("1got it \n", .{});
                    return "-";
                }
            }
            
        }

        // Could just do all of the other checks for the other line here instead of going through another loop
        count +=1;
    }

    std.debug.print("--- Map 1---\n", .{});
    var it = mixedHashmap1.iterator();
    while (it.next()) |entry| {
        std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
    }

    std.debug.print("--- Map 2---\n", .{});
    it = mixedHashmap2.iterator();
    while (it.next()) |entry| {
        std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
    }

    //Use a union find perhaps?
    for (line1split.items) |value| {
        if(value[0] == '<'){
            const val = mixedHashmap1.get(value);
            if(val)|val1|{
                try res.appendSlice(val1.word[0..]);
                try res.append(' ');                
            }else {
                try res.appendSlice("a ");
            }
        }else {
            try res.appendSlice(value[0..]);
            try res.append(' ');
        }
    }

    for (line2split.items) |value| {
        if(value[0] == '<'){
            const val = mixedHashmap2.get(value);
            if(val)|val1|{
                std.debug.print("res2:{s}\n", .{val1.word});
                try res2.appendSlice(val1.word[0..]);
                try res2.append(' ');
            }else {
                try res2.appendSlice("a ");
            }
        }else {
            try res2.appendSlice(value[0..]);
            try res2.append(' ');
        }
    }

    const result = try res.toOwnedSlice();
    const result2 = try res2.toOwnedSlice();
    std.debug.print("restult1: {s}\nresult2: {s}\n", .{result, result2});


    if (std.mem.eql(u8,result,result2)) {
        return result;
    }
    return "-";
}

fn checkForReferense(node: *Node, targetNode: []u8) bool {
    for(node.nodeList.items)|nodes| {
        if (std.mem.eql(u8,nodes,targetNode)) {
        } else {
            return false;
        }
    }
    return true;
}
// maybe I have problem with hashmap
fn propagateWord(node: *Node, message: []u8, hashMapOtherSide: std.HashMap([]const u8, *Node, std.hash_map.StringContext, 80), hashMapCurrSide: std.HashMap([]const u8, *Node, std.hash_map.StringContext, 80))!void{
    std.debug.print("---\n", .{});
    std.debug.print("started propagate\n", .{});
    std.debug.print("node {s}\n", .{node.value});
    std.debug.print("propagated: {s}\n", .{message});
    std.debug.print("Neiboughrs inside: ", .{});
    for(node.nodeList.items)|items|{
        std.debug.print("{s} ", .{items});
    }
    std.debug.print("\n", .{});
    
    var it = hashMapOtherSide.iterator();
    while (it.next()) |entry| {
        std.debug.print("Key: {s}, Value: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*.value});
    }

    for (node.nodeList.items) |neighbours| {
        const node1 = hashMapOtherSide.get(neighbours);
        std.debug.print("we never get here\n", .{});
        if (node1)|neighbourNode| {
            std.debug.print("Node {s} gave Neighbour:{s} :{s}: {s}\n", .{node.value,neighbours,neighbourNode.value,message});
            if (std.mem.eql(u8, neighbourNode.word, message)) {
                continue;
            }
            neighbourNode.word = message;
            try propagateWord(neighbourNode, message, hashMapCurrSide,hashMapOtherSide);
        }
    }
    std.debug.print("---\n", .{});
    return;
}


pub fn printRes(res: std.ArrayList([]const u8)) !void {
    const stdout = std.io.getStdOut();
    for (res.items) |value| {
        try stdout.writer().print("{s}\n", .{value});
    }

}


pub fn main() !void {

    const stdin = std.io.getStdIn();

    const allocator = std.heap.page_allocator;

    var buffer: [1024]u8 = undefined;

    const input = try readFullInputArrays(allocator, stdin.reader(), buffer[0..]);

    const tes= try solveAll(input, allocator);

    try printRes(tes);

    buffer[1] = '1';

    // for (intArray.items) |s| {
    //     for (s) |d| {
    //         std.debug.print("{d} ", .{d});
    //     }
    //     std.debug.print("\n", .{});
    // }

    for (input.items) |value| {
        allocator.free(value);
    }
    input.deinit();
}


// another thing I could do is just build the string while going along and then in the key value part we just store a value back to the position of the word we where going to point there, that way it goes way faster probably, 
// we arrive with two built strings thereby not having to test different things and build a string  





// if < string > check if the var i already used, then compare this to position in other line or add the potentiall val
// otherwise add this as this lines permanent version
// what happens if the other lines position is a var, maybe we can just do the compare at the same time
// Compare the two lines potentiall versions and check if they are the same if they are it's a match

// problem prob is if both have a var from each side that is do not have the same word
