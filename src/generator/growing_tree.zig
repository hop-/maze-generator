const std = @import("std");
const Rng = @import("../utils.zig").Rng;
const Maze = @import("../core/maze.zig").Maze;
const Coordinates = @import("../core/coordinates.zig").Coordinates;
const Direction = @import("../core/direction.zig").Direction;
const ALL_DIRECTIONS = @import("../core/direction.zig").ALL_DIRECTIONS;

const min_hardness: u8 = 0;
const max_hardness: u8 = std.math.maxInt(u8);

const BranchHead = struct {
    coords: Coordinates,
    length: usize,
};

const GenerationContext = struct {
    allocator: std.mem.Allocator,
    maze: *Maze,
    rng: *Rng,
    hardness: u8,
    visiteds: [][]bool,
    branch_heads: std.ArrayList(BranchHead),
    furthermost_branch_head: BranchHead,
};

pub fn generate(parrent_allocator: std.mem.Allocator, maze: *Maze, rng: *Rng, hardness: u8, thread_pool: *std.Thread.Pool) !void {
    // Allocator
    var arena = std.heap.ArenaAllocator.init(parrent_allocator);
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

    // Define the start
    const start = Coordinates{
        .x = rng.intRangeAtMost(isize, 0, maze.width - 1),
        .y = rng.intRangeAtMost(isize, 0, maze.height - 1),
    };
    maze.start = start;
    const start_x: usize = @intCast(start.x);
    const start_y: usize = @intCast(start.y);
    visiteds[start_y][start_x] = true;

    const furthermost_branch_head = BranchHead{
        .coords = start,
        .length = 0,
    };
    try branch_heads.append(allocator, furthermost_branch_head);

    // Wait group to synchronize threads
    var wg = std.Thread.WaitGroup{};

    var ctx = GenerationContext{
        .allocator = allocator,
        .maze = maze,
        .rng = rng,
        .hardness = hardness,
        .visiteds = visiteds,
        .branch_heads = branch_heads,
        .furthermost_branch_head = furthermost_branch_head,
    };

    // Start the maze generation in the thread pool
    thread_pool.spawnWg(&wg, generateMazeTree, .{&ctx});

    // Wait for all threads to complete
    wg.wait();

    // After generation, set finish point
    ctx.maze.finish = ctx.furthermost_branch_head.coords;
}

fn generateMazeTree(ctx: *GenerationContext) void {
    // Allocator
    var arena = std.heap.ArenaAllocator.init(ctx.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    while (ctx.branch_heads.items.len > 0) {
        // Select a branch head
        const index = getBranchHeadIndex(ctx.branch_heads.items.len, ctx.hardness, ctx.rng);
        const current = ctx.branch_heads.items[index];

        // Find unvisited neighbors
        const neighbor_directions = findUnvisitedNeighbors(allocator, ctx.maze, current.coords, ctx.visiteds) orelse {
            continue;
        };

        if (neighbor_directions.items.len == 0) {
            // No unvisited neighbors, remove branch head
            _ = ctx.branch_heads.swapRemove(index);
            continue;
        }

        // Choose a random neighbor direction
        const dir_index = ctx.rng.intRangeAtMost(usize, 0, neighbor_directions.items.len - 1);
        const chosen_direction = neighbor_directions.items[dir_index];
        const neighbor_coords = ctx.maze.openPathLockFree(current.coords, chosen_direction) orelse continue;

        // Mark neighbor as visited and add to branch heads
        const neighbor_x: usize = @intCast(neighbor_coords.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y);

        ctx.visiteds[neighbor_y][neighbor_x] = true;

        const neighbor_branch_head = BranchHead{
            .coords = neighbor_coords,
            .length = current.length + 1,
        };

        // Update furthermost branch head
        if (neighbor_branch_head.length > ctx.furthermost_branch_head.length) {
            ctx.furthermost_branch_head = neighbor_branch_head;
        }

        ctx.branch_heads.append(ctx.allocator, neighbor_branch_head) catch {};
    }
}

fn getBranchHeadIndex(length: usize, hardness: u8, rng: *Rng) usize {
    const r = rng.intRangeAtMost(u8, min_hardness, max_hardness);
    if (r < hardness) {
        return length - 1; // Most recently added
    } else {
        return rng.intRangeAtMost(usize, 0, length - 1); // Random
    }
}

fn findUnvisitedNeighbors(allocator: std.mem.Allocator, maze: *Maze, current_coords: Coordinates, visiteds: [][]bool) ?std.ArrayList(Direction) {
    var neighbor_directions = std.ArrayList(Direction).empty;

    for (ALL_DIRECTIONS) |dir| {
        const neighbor_coords = current_coords.move(dir, 1);
        if (neighbor_coords.x < 0 or neighbor_coords.x >= maze.width or
            neighbor_coords.y < 0 or neighbor_coords.y >= maze.height)
        {
            continue;
        }

        const neighbor_x: usize = @intCast(neighbor_coords.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y);
        if (!visiteds[neighbor_y][neighbor_x]) {
            neighbor_directions.append(allocator, dir) catch {
                return null;
            };
        }
    }

    return neighbor_directions;
}
