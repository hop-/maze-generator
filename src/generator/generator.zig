const Maze = @import("../maze.zig").Maze;
const Config = @import("config.zig").Config;
const mergeWithDefault = @import("config.zig").mergeWithDefault;
const generateGrowingTree = @import("growing_tree.zig").generate;

pub fn generate(maze: *Maze, config: Config) void {
    switch (config.algorithm) {
        .growing_tree => generateGrowingTree(maze, config.seed, config.hardness),
    }
}
