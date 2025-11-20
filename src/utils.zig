const std = @import("std");

pub const Rng = std.Random.DefaultPrng;

pub fn initRng(seed: ?u64) Rng {
    const s: u64 = seed orelse @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));

    return std.Random.DefaultPrng.init(s);
}
