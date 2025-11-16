const std = @import("std");

pub fn initRng(seed: ?u64) std.Random.DefaultPrng {
    const s: u64 = seed orelse @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));

    return std.Random.DefaultPrng.init(s);
}
