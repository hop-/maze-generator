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

const SegmentCoordinates = struct {
    start: Coordinates,
    end: Coordinates,
};

const GenerationContext = struct {
    allocator: std.mem.Allocator,
    maze: *Maze,
    rng: *Rng,
    hardness: u8,
    segment: SegmentCoordinates,
};

pub fn generate(maze: *Maze, rng: *Rng, hardness: u8, thread_pool: *std.Thread.Pool) !void {
    // Allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const thread_count = thread_pool.threads.len;
    var segments = try getSegmentCoordinates(allocator, maze.height, maze.width, thread_count);
    defer segments.deinit(allocator);

    var wg = std.Thread.WaitGroup{};

    for (segments.items) |segment| {
        var ctx = GenerationContext{
            .allocator = allocator,
            .maze = maze,
            .rng = rng,
            .hardness = hardness,
            .segment = segment,
        };

        // Start the maze generation in the thread pool
        thread_pool.spawnWg(&wg, generateMazeTreeForSegment, .{&ctx});
    }

    // Wait for all threads to complete
    thread_pool.waitAndWork(&wg);
}

fn getSegmentationCount(maze_height: isize, maze_width: isize, preferred_count: usize) struct { h: usize, w: usize } {
    const normal_segmenting_size = 5;

    // Currently support segmentation only by height
    _ = maze_width; // ignore width for now
    const w_segments: usize = 1;
    const h_segments: usize = @max(@as(usize, @intCast(maze_height)) / normal_segmenting_size, preferred_count);

    return .{ .h = h_segments, .w = w_segments };
}

fn getSegmentCoordinates(allocator: std.mem.Allocator, maze_height: isize, maze_width: isize, preferred_count: usize) !std.ArrayList(SegmentCoordinates) {
    const segmentation_counts = getSegmentationCount(maze_height, maze_width, preferred_count);
    const h_segments = segmentation_counts.h;
    const w_segments = segmentation_counts.w;

    const segment_height: isize = @divFloor(maze_height, @as(isize, @intCast(h_segments)));
    const segment_width: isize = @divFloor(maze_width, @as(isize, @intCast(w_segments)));

    var segments = try std.ArrayList(SegmentCoordinates).initCapacity(allocator, h_segments * w_segments);

    for (0..h_segments) |h_idx| {
        const start_y: isize = @as(isize, @intCast(h_idx)) * segment_height;
        const end_y: isize = if (h_idx == h_segments - 1) maze_height - 1 else start_y + segment_height - 1;

        for (0..w_segments) |w_idx| {
            const start_x: isize = @as(isize, @intCast(w_idx)) * segment_width;
            const end_x: isize = if (w_idx == w_segments - 1) maze_width - 1 else start_x + segment_width - 1;
            segments.appendAssumeCapacity(.{
                .start = Coordinates{ .x = start_x, .y = start_y },
                .end = Coordinates{ .x = end_x, .y = end_y },
            });
        }
    }

    return segments;
}

fn generateMazeTreeForSegment(ctx: *GenerationContext) void {
    // Initialize visited grid for the segment
    const visiteds = ctx.allocator.alloc([]bool, @as(usize, @intCast(ctx.segment.end.y - ctx.segment.start.y + 1))) catch return;
    for (visiteds) |*row| {
        row.* = ctx.allocator.alloc(bool, @as(usize, @intCast(ctx.segment.end.x - ctx.segment.start.x + 1))) catch return;
        @memset(row.*, false);
    }

    // Initialize branch heads list
    var branch_heads = std.ArrayList(BranchHead).empty;
    defer branch_heads.deinit(ctx.allocator);

    // Define the start
    const start = Coordinates{
        .x = ctx.rng.random().intRangeAtMost(isize, ctx.segment.start.x, ctx.segment.end.x),
        .y = ctx.rng.random().intRangeAtMost(isize, ctx.segment.start.y, ctx.segment.end.y),
    };
    const start_x: usize = @intCast(start.x - ctx.segment.start.x);
    const start_y: usize = @intCast(start.y - ctx.segment.start.y);
    visiteds[start_y][start_x] = true;

    const furthermost_branch_head = BranchHead{
        .coords = start,
        .length = 0,
    };
    branch_heads.append(ctx.allocator, furthermost_branch_head) catch {};

    while (branch_heads.items.len > 0) {
        // Select a branch head
        const index = getBranchHeadIndex(branch_heads.items.len, ctx.hardness, ctx.rng);
        const current = branch_heads.items[index];

        // Find unvisited neighbors
        var neighbor_directions = findUnvisitedNeighbors(ctx.allocator, ctx.maze, ctx.segment.start, current.coords, visiteds) orelse {
            continue;
        };
        defer neighbor_directions.deinit(ctx.allocator);

        if (neighbor_directions.items.len == 0) {
            // No unvisited neighbors, remove branch head
            _ = branch_heads.swapRemove(index);
            continue;
        }

        // Choose a random neighbor direction
        const dir_index = ctx.rng.random().intRangeAtMost(usize, 0, neighbor_directions.items.len - 1);
        const chosen_direction = neighbor_directions.items[dir_index];
        const neighbor_coords = ctx.maze.openPath(current.coords, chosen_direction) orelse continue;

        // Mark neighbor as visited and add to branch heads
        const neighbor_x: usize = @intCast(neighbor_coords.x - ctx.segment.start.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y - ctx.segment.start.y);

        visiteds[neighbor_y][neighbor_x] = true;

        const neighbor_branch_head = BranchHead{
            .coords = neighbor_coords,
            .length = current.length + 1,
        };

        branch_heads.append(ctx.allocator, neighbor_branch_head) catch {};
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

fn findUnvisitedNeighbors(allocator: std.mem.Allocator, maze: *Maze, segment_start: Coordinates, current_coords: Coordinates, visiteds: [][]bool) ?std.ArrayList(Direction) {
    var neighbor_directions = std.ArrayList(Direction).empty;

    for (ALL_DIRECTIONS) |dir| {
        const neighbor_coords = current_coords.move(dir, 1);
        if (neighbor_coords.x < segment_start.x or neighbor_coords.x >= maze.width or
            neighbor_coords.y < segment_start.y or neighbor_coords.y >= maze.height)
        {
            continue;
        }

        const neighbor_x: usize = @intCast(neighbor_coords.x - segment_start.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y - segment_start.y);
        if (!visiteds[neighbor_y][neighbor_x]) {
            neighbor_directions.append(allocator, dir) catch {
                return null;
            };
        }
    }

    return neighbor_directions;
}
