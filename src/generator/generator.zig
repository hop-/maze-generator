const std = @import("std");
const Config = @import("types.zig").Config;
const Maze = @import("../core/maze.zig").Maze;
const Rng = @import("../utils.zig").Rng;
// algorithms
const generateGrowingTree = @import("growing_tree.zig").generate;
const generatePatchGrowingTree = @import("patch_growing_tree.zig").generate;

pub fn generate(allocator: std.mem.Allocator, maze: *Maze, config: Config) !void {
    // Dedicated threaded I/O acting as the worker pool. The calling thread also
    // runs tasks once the limit is reached, so `thread_count - 1` workers plus
    // the caller give `thread_count` threads in total.
    var threaded = std.Io.Threaded.init(allocator, .{
        .async_limit = .limited(config.thread_count -| 1),
    });
    defer threaded.deinit();
    const io = threaded.io();

    // Initialize RNG
    var rng = Rng.init(io, config.seed);

    switch (config.algorithm) {
        .growing_tree => try generateGrowingTree(allocator, io, maze, &rng, config.hardness),
        .patch_growing_tree => try generatePatchGrowingTree(allocator, io, maze, &rng, config.hardness),
    }
}
