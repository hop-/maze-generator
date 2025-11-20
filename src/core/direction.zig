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

    pub fn dX(self: Direction) i8 {
        return switch (self) {
            .north => 0,
            .south => 0,
            .east => 1,
            .west => -1,
        };
    }

    pub fn dY(self: Direction) i8 {
        return switch (self) {
            .north => -1,
            .south => 1,
            .east => 0,
            .west => 0,
        };
    }
};

pub const ALL_DIRECTIONS = [_]Direction{ .north, .south, .east, .west };
