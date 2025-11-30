const std = @import("std");

pub const Rng = struct {
    mutex: std.Thread.Mutex,
    rng: std.Random.DefaultPrng,

    pub fn init(seed: ?u64) Rng {
        const s: u64 = seed orelse @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
        return Rng{
            .mutex = std.Thread.Mutex{},
            .rng = std.Random.DefaultPrng.init(s),
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
