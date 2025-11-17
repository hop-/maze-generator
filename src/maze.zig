const std = @import("std");
const Coordinates = @import("coordinates.zig").Coordinates;

pub const Direction = enum(u8) {
    north = 1 << 0,
    south = 1 << 1,
    east = 1 << 2,
    west = 1 << 3,

    pub fn opposite(self: Direction) Direction {
        return switch (self) {
            .north => .south,
            .south => .north,
            .east => .west,
            .west => .east,
        };
    }

    pub fn dX(self: Direction) i32 {
        return switch (self) {
            .north => 0,
            .south => 0,
            .east => 1,
            .west => -1,
        };
    }

    pub fn dY(self: Direction) i32 {
        return switch (self) {
            .north => -1,
            .south => 1,
            .east => 0,
            .west => 0,
        };
    }
};

pub const Cell = struct {
    directions: u8,

    fn init() Cell {
        return Cell{ .directions = 0 };
    }

    pub fn hasDirection(self: Cell, dir: Direction) bool {
        return (self.directions & @as(u8, @intFromEnum(dir))) != 0;
    }
};

pub const Maze = struct {
    // Maze dimensions
    width: usize,
    height: usize,

    // 2D grid ((true = wall, false = path)
    grid: [][]Cell,

    // Start and finish positions
    start: ?Coordinates,
    finish: ?Coordinates,

    // Allocator for memory management
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Maze {
        const grid = try allocator.alloc([]Cell, height);
        for (grid) |*row| {
            row.* = try allocator.alloc(Cell, width);
            for (row.*) |*cell| {
                cell.* = Cell.init(); // Initialize all cells as walls
            }
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

    pub fn openPath(self: *Maze, cell_coordinates: Coordinates, direction: Direction) Coordinates {
        const x = cell_coordinates.x;
        const y = cell_coordinates.y;

        // Open path in the current cell
        self.grid[y][x].directions |= @as(u8, direction);

        // Calculate neighbor coordinates
        const neighbor_x: usize = x + direction.dX();
        const neighbor_y: usize = y + direction.dY();

        // Open path in the neighboring cell
        self.grid[neighbor_y][neighbor_x].directions |= @as(u8, direction.opposite());

        return .{ .x = neighbor_x, .y = neighbor_y };
    }
};
