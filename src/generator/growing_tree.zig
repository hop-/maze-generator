const std = @import("std");
const utils = @import("../utils.zig");
const Maze = @import("../core/maze.zig").Maze;
const Coordinates = @import("../core/coordinates.zig").Coordinates;
const Direction = @import("../core/direction.zig").Direction;
const ALL_DIRECTIONS = @import("../core/direction.zig").ALL_DIRECTIONS;

const max_hardness: u8 = std.math.maxInt(u8);
const min_hardness: u8 = 0;

const BranchHead = struct {
    coords: Coordinates,
    length: usize,
};

pub fn generate(maze: *Maze, seed: u64, hardness: u8) !void {
    // Initialize RNG
    var rng = utils.initRng(seed);

    // Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize visited grid
    const visiteds = try allocator.alloc([]bool, @as(usize, @intCast(maze.height)));
    for (visiteds) |*row| {
        row.* = try allocator.alloc(bool, @as(usize, @intCast(maze.width)));
        @memset(row.*, false);
    }

    // Initialize branch heads list
    var branch_heads = std.ArrayList(BranchHead).empty;
    defer branch_heads.deinit(allocator);

    // Define the start
    const start = Coordinates{
        .x = rng.random().intRangeAtMost(isize, 0, maze.width - 1),
        .y = rng.random().intRangeAtMost(isize, 0, maze.height - 1),
    };
    maze.start = start;
    const start_x: usize = @intCast(start.x);
    const start_y: usize = @intCast(start.y);
    visiteds[start_y][start_x] = true;

    var furthermost_branch_head = BranchHead{
        .coords = start,
        .length = 0,
    };
    try branch_heads.append(allocator, furthermost_branch_head);

    while (branch_heads.items.len > 0) {
        // Select a branch head
        const index = getBranchHeadIndex(branch_heads.items.len, hardness, &rng);
        const current = branch_heads.items[index];

        // Find unvisited neighbors
        var neighbor_directions = std.ArrayList(Direction).empty;
        defer neighbor_directions.deinit(allocator);
        for (ALL_DIRECTIONS) |dir| {
            const neighbor_coords = current.coords.move(dir, 1);
            if (neighbor_coords.x < 0 or neighbor_coords.x >= maze.width or
                neighbor_coords.y < 0 or neighbor_coords.y >= maze.height)
            {
                continue;
            }
            const neighbor_x: usize = @intCast(neighbor_coords.x);
            const neighbor_y: usize = @intCast(neighbor_coords.y);
            if (!visiteds[neighbor_y][neighbor_x]) {
                try neighbor_directions.append(allocator, dir);
            }
        }
        if (neighbor_directions.items.len == 0) {
            // No unvisited neighbors, remove branch head
            _ = branch_heads.swapRemove(index);
            continue;
        }

        // Choose a random neighbor direction
        const dir_index = rng.random().intRangeAtMost(usize, 0, neighbor_directions.items.len - 1);
        const chosen_direction = neighbor_directions.items[dir_index];
        const neighbor_coords = try maze.openPath(current.coords, chosen_direction);

        // Mark neighbor as visited and add to branch heads
        const neighbor_x: usize = @intCast(neighbor_coords.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y);
        visiteds[neighbor_y][neighbor_x] = true;

        const neighbor_branch_head = BranchHead{
            .coords = neighbor_coords,
            .length = current.length + 1,
        };

        // Update furthermost branch head
        if (neighbor_branch_head.length > furthermost_branch_head.length) {
            furthermost_branch_head = neighbor_branch_head;
        }

        try branch_heads.append(allocator, neighbor_branch_head);
    }

    maze.finish = furthermost_branch_head.coords;
}

fn getBranchHeadIndex(length: usize, hardness: u8, rng: *utils.Rng) usize {
    const r = rng.random().intRangeAtMost(u8, min_hardness, max_hardness);
    if (r < hardness) {
        return length - 1; // Most recently added
    } else {
        return rng.random().intRangeAtMost(usize, 0, length - 1); // Random
    }
}
