const Direction = @import("direction.zig").Direction;

pub const Cell = struct {
    directions: u8,

    pub fn init() Cell {
        return Cell{ .directions = 0 };
    }

    pub fn hasDirection(self: Cell, dir: Direction) bool {
        return (self.directions & @as(u8, @intFromEnum(dir))) != 0;
    }

    pub fn openDirection(self: *Cell, dir: Direction) void {
        self.directions |= @as(u8, @intFromEnum(dir));
    }
};
