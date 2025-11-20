const Direction = @import("direction.zig").Direction;

pub const Coordinates = struct {
    x: isize,
    y: isize,

    pub fn move(self: Coordinates, dir: Direction, steps: isize) Coordinates {
        return Coordinates{
            .x = self.x + (dir.dX() * steps),
            .y = self.y + (dir.dY() * steps),
        };
    }
};
