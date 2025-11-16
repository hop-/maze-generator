const std = @import("std");
const Maze = @import("maze.zig").Maze;

pub const Writer = struct {
    pub fn write(maze: *const Maze, writer: *std.Io.Writer) !void {
        for (0..maze.height) |y| {
            for (0..maze.width) |x| {
                if (maze.start) |start| {
                    if (x == start.x and y == start.y) {
                        try writer.print(">M", .{});
                        continue;
                    }
                }
                if (maze.finish) |finish| {
                    if (x == finish.x and y == finish.y) {
                        try writer.print("M>", .{});
                        continue;
                    }
                }
                const cell = maze.grid[y][x];
                if (cell) {
                    try writer.print("[]", .{});
                } else {
                    try writer.print("  ", .{});
                }
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
