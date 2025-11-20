const std = @import("std");
const Maze = @import("core/maze.zig").Maze;
const Coordinates = @import("core/coordinates.zig").Coordinates;
const Direction = @import("core/direction.zig").Direction;

pub const Writer = struct {
    pub fn write(maze: *const Maze, writer: *std.Io.Writer) !void {
        // Allocator
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // The map representation 0 = wall, 1 = path, 2 = start, 3 = finish
        const map_height = @as(usize, @intCast(maze.height)) * 2 + 1;
        const map_width = @as(usize, @intCast(maze.width)) * 2 + 1;
        const map = try allocator.alloc([]u8, map_height);
        for (map) |*row| {
            row.* = try allocator.alloc(u8, map_width);
            @memset(row.*, 0); // Walls
        }

        // Convert maze cells to map representation
        for (0..@intCast(maze.height)) |y| {
            for (0..@intCast(maze.width)) |x| {
                const cell = maze.grid[y][x];
                const map_x = x * 2 + 1;
                const map_y = y * 2 + 1;
                const map_coordinates = Coordinates{
                    .x = @intCast(map_x),
                    .y = @intCast(map_y),
                };
                map[map_y][map_x] = 1; // Path
                if (cell.hasDirection(Direction.north)) {
                    const neighbor_coords = map_coordinates.move(Direction.north, 1);
                    if (neighbor_coords.y < map_height and neighbor_coords.x < map_width) {
                        const neighbor_x: usize = @intCast(neighbor_coords.x);
                        const neighbor_y: usize = @intCast(neighbor_coords.y);
                        map[neighbor_y][neighbor_x] = 1; // Path
                    }
                }
                if (cell.hasDirection(Direction.east)) {
                    const neighbor_coords = map_coordinates.move(Direction.east, 1);
                    if (neighbor_coords.y < map_height and neighbor_coords.x < map_width) {
                        const neighbor_x: usize = @intCast(neighbor_coords.x);
                        const neighbor_y: usize = @intCast(neighbor_coords.y);
                        map[neighbor_y][neighbor_x] = 1; // Path
                    }
                }
            }
        }
        // Mark start and finish
        if (maze.start) |start| {
            const start_map_y = @as(usize, @intCast(start.y)) * 2 + 1;
            const start_map_x = @as(usize, @intCast(start.x)) * 2 + 1;
            map[start_map_y][start_map_x] = 2; // Start
        }
        if (maze.finish) |finish| {
            const finish_map_y = @as(usize, @intCast(finish.y)) * 2 + 1;
            const finish_map_x = @as(usize, @intCast(finish.x)) * 2 + 1;
            map[finish_map_y][finish_map_x] = 3; // Finish
        }

        for (0..map_height) |y| {
            for (0..map_width) |x| {
                const cell = map[y][x];
                try writer.print("{s}", .{switch (cell) {
                    0 => "[]",
                    1 => "  ",
                    2 => ">M",
                    3 => "M>",
                    else => "??",
                }});
            }
            try writer.print("\n", .{});
        }
        try writer.flush();
    }
    pub fn writeToFile(maze: *const Maze, file_path: []const u8) !void {
        var file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
        defer file.close();

        var write_to_file_buffer: [1024]u8 = undefined;
        var file_writer = file.writer(&write_to_file_buffer);
        const writer = &file_writer.interface;

        return Writer.write(maze, writer);
    }
};
