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
    branch_mutex: std.Thread.Mutex,
    visited_mutex: std.Thread.Mutex,
    allocator: std.mem.Allocator,
    maze: *Maze,
    rng: *Rng,
    hardness: u8,
    visiteds: [][]bool,
    branch_heads: std.ArrayList(BranchHead),
    furthermost_branch_head: BranchHead,
};

pub fn generate(maze: *Maze, rng: *Rng, hardness: u8, thread_pool: *std.Thread.Pool) !void {
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

    const furthermost_branch_head = BranchHead{
        .coords = start,
        .length = 0,
    };
    try branch_heads.append(allocator, furthermost_branch_head);
    var wg = std.Thread.WaitGroup{};

    var ctx = GenerationContext{
        .branch_mutex = std.Thread.Mutex{},
        .visited_mutex = std.Thread.Mutex{},
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
    thread_pool.waitAndWork(&wg);

    // After generation, set finish point
    ctx.maze.finish = ctx.furthermost_branch_head.coords;
}

fn generateMazeTree(ctx: *GenerationContext) void {
    ctx.branch_mutex.lock();
    defer ctx.branch_mutex.unlock();

    while (ctx.branch_heads.items.len > 0) {
        // Select a branch head
        const index = getBranchHeadIndex(ctx.branch_heads.items.len, ctx.hardness, ctx.rng);
        const current = ctx.branch_heads.items[index];

        // Find unvisited neighbors
        var neighbor_directions = findUnvisitedNeighbors(ctx.allocator, &ctx.visited_mutex, ctx.maze, current.coords, ctx.visiteds) orelse {
            continue;
        };
        defer neighbor_directions.deinit(ctx.allocator);

        if (neighbor_directions.items.len == 0) {
            // No unvisited neighbors, remove branch head
            _ = ctx.branch_heads.swapRemove(index);
            continue;
        }

        // Choose a random neighbor direction
        const dir_index = ctx.rng.random().intRangeAtMost(usize, 0, neighbor_directions.items.len - 1);
        const chosen_direction = neighbor_directions.items[dir_index];
        const neighbor_coords = ctx.maze.openPath(current.coords, chosen_direction) orelse continue;

        // Mark neighbor as visited and add to branch heads
        const neighbor_x: usize = @intCast(neighbor_coords.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y);

        ctx.visited_mutex.lock();
        ctx.visiteds[neighbor_y][neighbor_x] = true;
        ctx.visited_mutex.unlock();

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
    const r = rng.random().intRangeAtMost(u8, min_hardness, max_hardness);
    if (r < hardness) {
        return length - 1; // Most recently added
    } else {
        return rng.random().intRangeAtMost(usize, 0, length - 1); // Random
    }
}

fn findUnvisitedNeighbors(allocator: std.mem.Allocator, mutex: *std.Thread.Mutex, maze: *Maze, current_coords: Coordinates, visiteds: [][]bool) ?std.ArrayList(Direction) {
    var neighbor_directions = std.ArrayList(Direction).empty;

    mutex.lock();
    defer mutex.unlock();

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
