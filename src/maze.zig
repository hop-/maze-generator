const std = @import("std");
const Coordinates = @import("coordinates.zig").Coordinates;

pub const Maze = struct {
    // Maze dimensions
    width: usize,
    height: usize,

    // 2D grid ((true = wall, false = path)
    grid: [][]bool,

    // Start and finish positions
    start: ?Coordinates,
    finish: ?Coordinates,

    // Allocator for memory management
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Maze {
        const grid = try allocator.alloc([]bool, height);
        for (grid) |*row| {
            row.* = try allocator.alloc(bool, width);
            @memset(row.*, true);
        }

        return Maze{
            .width = width,
            .height = height,
            .grid = grid,
            .start = null,
            .finish = null,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Maze) void {
        for (self.grid) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.grid);
    }
};
