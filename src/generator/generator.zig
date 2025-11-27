const std = @import("std");
const Config = @import("types.zig").Config;
const Maze = @import("../core/maze.zig").Maze;
const initRng = @import("../utils.zig").initRng;
// algorithms
const generateGrowingTree = @import("growing_tree.zig").generate;
const generatePatchGrowingTree = @import("patch_growing_tree.zig").generate;

pub fn generate(maze: *Maze, config: Config) !void {
    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize RNG
    var rng = initRng(config.seed);

    // Initialize thread pool
    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{
        .allocator = allocator,
        .n_jobs = config.thread_count,
    });
    defer thread_pool.deinit();

    switch (config.algorithm) {
        .growing_tree => try generateGrowingTree(maze, &rng, config.hardness, &thread_pool),
        .patch_growing_tree => try generatePatchGrowingTree(maze, &rng, config.hardness, &thread_pool),
    }
}
