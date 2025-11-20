const std = @import("std");
const Cell = @import("cell.zig").Cell;
const Coordinates = @import("coordinates.zig").Coordinates;
const Direction = @import("direction.zig").Direction;

pub const Maze = struct {
    // Maze dimensions
    width: isize,
    height: isize,

    // 2D grid ((true = wall, false = path)
    grid: [][]Cell,

    // Start and finish positions
    start: ?Coordinates,
    finish: ?Coordinates,

    // Allocator for memory management
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: isize, height: isize) !Maze {
        const grid = try allocator.alloc([]Cell, @intCast(height));
        for (grid) |*row| {
            row.* = try allocator.alloc(Cell, @intCast(width));
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

    pub fn openPath(self: *Maze, cell_coordinates: Coordinates, direction: Direction) !Coordinates {
        // Check if coordinates are within bounds
        if (cell_coordinates.x < 0 or cell_coordinates.x >= self.width or
            cell_coordinates.y < 0 or cell_coordinates.y >= self.height)
        {
            return error.IndexOutOfBounds;
        }
        const x: usize = @intCast(cell_coordinates.x);
        const y: usize = @intCast(cell_coordinates.y);

        // Open path in the current cell
        self.grid[y][x].openDirection(direction);

        // Calculate neighbor coordinates
        const neighbor_coords = cell_coordinates.move(direction, 1);
        if (neighbor_coords.x < 0 or neighbor_coords.x >= self.width or
            neighbor_coords.y < 0 or neighbor_coords.y >= self.height)
        {
            return error.IndexOutOfBounds;
        }

        const neighbor_x: usize = @intCast(neighbor_coords.x);
        const neighbor_y: usize = @intCast(neighbor_coords.y);

        // Open path in the neighboring cell
        self.grid[neighbor_y][neighbor_x].openDirection(direction.opposite());

        return neighbor_coords;
    }
};
