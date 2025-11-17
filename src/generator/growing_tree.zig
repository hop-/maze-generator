const Maze = @import("../maze.zig").Maze;
const utils = @import("../utils.zig");

pub fn generate(maze: *Maze, seed: u64, hardness: u8) void {
    // Initialize RNG
    var rng = utils.initRng(seed);
    // Define the start
    const startX = rng.random().intRangeAtMost(usize, 0, maze.width - 1);
    const startY = rng.random().intRangeAtMost(usize, 0, maze.height - 1);

    maze.start = .{ .x = startX, .y = startY };

    // TODO: Implement Growing Tree algorithm
    _ = hardness; // Placeholder to avoid unused variable warning
}
