const Config = @import("config.zig").Config;
const mergeWithDefault = @import("config.zig").mergeWithDefault;
const generateGrowingTree = @import("growing_tree.zig").generate;
const Maze = @import("../core/maze.zig").Maze;

pub fn generate(maze: *Maze, config: Config) !void {
    switch (config.algorithm) {
        .growing_tree => try generateGrowingTree(maze, config.seed, config.hardness),
    }
}
