const std = @import("std");

pub const Rng = std.Random.DefaultPrng;

pub fn initRng(seed: ?u64) Rng {
    const s: u64 = seed orelse @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));

    return std.Random.DefaultPrng.init(s);
}

pub fn getProcessArgs(allocator: std.mem.Allocator) !std.ArrayList([:0]const u8) {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();

    var args = std.ArrayList([:0]const u8).empty;

    while (it.next()) |arg| {
        try args.append(allocator, arg);
    }

    return args;
}
