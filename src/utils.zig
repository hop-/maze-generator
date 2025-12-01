const std = @import("std");

pub const Rng = struct {
    mutex: std.Thread.Mutex,
    rng: std.Random.DefaultPrng,
    seed: u64,

    pub fn init(seed: ?u64) Rng {
        const s: u64 = seed orelse @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
        return Rng{
            .mutex = std.Thread.Mutex{},
            .rng = std.Random.DefaultPrng.init(s),
            .seed = s,
        };
    }

    pub fn intRangeAtMost(self: *Rng, T: type, min: T, max: T) T {
        self.mutex.lock();
        defer self.mutex.unlock();

        return self.rng.random().intRangeAtMost(T, min, max);
    }

    pub fn int(self: *Rng, T: type) T {
        self.mutex.lock();
        defer self.mutex.unlock();

        return self.rng.random().int(T);
    }
};

pub fn getProcessArgs(allocator: std.mem.Allocator) !std.ArrayList([:0]const u8) {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();

    var args = std.ArrayList([:0]const u8).empty;

    while (it.next()) |arg| {
        try args.append(allocator, arg);
    }

    return args;
}

pub fn printHelp(stdout: *std.io.Writer, program_name: []const u8, params: struct {
    width: isize,
    height: isize,
    hardness: u8,
    algorithm: []const u8,
    algorithms: []const []const u8,
    file_path: []const u8,
    thread_count: usize,
}) !void {
    try stdout.print("Usage: {s} [option [value]]\n", .{program_name});
    try stdout.print("Options:\n", .{});
    try stdout.print("  --help, -h              Show this help message\n", .{});
    try stdout.print("  --width, -W <value>     Set the width of the maze (default: {d})\n", .{params.width});
    try stdout.print("  --height, -H <value>    Set the height of the maze (default: {d})\n", .{params.height});
    try stdout.print("  --seed, -s <value>      Set the random seed (default: random)\n", .{});
    try stdout.print("  --level, -l <level>     Set the hardness level (default: {d})\n", .{params.hardness});
    try stdout.print("                          Possible values: {d}-{d}\n", .{ 0, std.math.maxInt(u8) });
    try stdout.print("  --algorithm, -a <name>  Set the generation algorithm (default: {s})\n", .{params.algorithm});
    try stdout.print("                          Available algorithms:", .{});
    for (params.algorithms) |alg| {
        try stdout.print(" {s}", .{alg});
    }
    try stdout.print("\n", .{});
    try stdout.print("  --output, -o <path>     Set the output file path (default: {s})\n", .{params.file_path});
    try stdout.print("  --threads, -t <value>   Set the number of threads to use (default: {d})\n", .{params.thread_count});
    try stdout.flush();
}
