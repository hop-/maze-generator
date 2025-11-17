const std = @import("std");
const Maze = @import("maze.zig").Maze;
const Direction = @import("maze.zig").Direction;

pub const Writer = struct {
    pub fn write(maze: *const Maze, writer: *std.Io.Writer) !void {
        // Allocator
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        // The map representation 0 = wall, 1 = path, 2 = start, 3 = finish
        const map_height = maze.height * 2 + 1;
        const map_width = maze.width * 2 + 1;
        const map = try allocator.alloc([]u8, map_height);
        for (map) |*row| {
            row.* = try allocator.alloc(u8, map_width);
            @memset(row.*, 0); // Walls
        }

        // Convert maze cells to map representation
        for (0..maze.height) |y| {
            for (0..maze.width) |x| {
                const cell = maze.grid[y][x];
                const map_y = y * 2 + 1;
                const map_x = x * 2 + 1;
                map[map_y][map_x] = 1; // Path
                if (cell.hasDirection(Direction.north)) {
                    map[map_y + @as(usize, @intCast(Direction.north.dY()))][map_x + @as(usize, @intCast(Direction.north.dX()))] = 1; // Path
                }
                if (cell.hasDirection(Direction.east)) {
                    map[map_y + @as(usize, @intCast(Direction.east.dY()))][map_x + @as(usize, @intCast(Direction.east.dX()))] = 1; // Path
                }
            }
        }
        // Mark start and finish
        if (maze.start) |start| {
            const start_map_y = start.y * 2 + 1;
            const start_map_x = start.x * 2 + 1;
            map[start_map_y][start_map_x] = 2; // Start
        }
        if (maze.finish) |finish| {
            const finish_map_y = finish.y * 2 + 1;
            const finish_map_x = finish.x * 2 + 1;
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
