const std = @import("std");
const generator = @import("generator/generator.zig");
const Writer = @import("writer.zig").Writer;
const Maze = @import("core/maze.zig").Maze;

pub fn main() !void {
    // Init stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Initialize a general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try stdout.print("Maze Generator\n", .{});
    try stdout.flush();

    const width = 80;
    const height = 80;
    const seed = 42;
    const hardness = 5;

    try stdout.print("Generating maze of size {d}x{d}\n", .{ width, height });
    try stdout.print("Using seed: {d}\n", .{seed});
    try stdout.flush();

    // Create an empty maze
    var maze = try Maze.init(allocator, width, height);
    defer maze.deinit();

    // Generate walls
    try generator.generate(&maze, .{ .seed = seed, .hardness = hardness, .algorithm = .growing_tree });
    try stdout.print("Maze generation complete.\n", .{});
    try stdout.flush();

    // Write maze to file
    const file_path = "maze.txt";
    try Writer.writeToFile(&maze, file_path);

    try stdout.print("Maze written to {s}\n", .{file_path});
    try stdout.flush();
}
