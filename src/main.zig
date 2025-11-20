const std = @import("std");
const getProcessArgs = @import("utils.zig").getProcessArgs;
const initRng = @import("utils.zig").initRng;
const Options = @import("options.zig").Options;
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

    // Default parameters
    var width: isize = 20;
    var height: isize = 20;
    var hardness: u8 = 100;
    var seed: u64 = 0;

    // Parse command line arguments
    var process_args = try getProcessArgs(allocator);
    defer process_args.deinit(allocator);
    const opts = try Options.parse(process_args.items);

    if (opts.help) {
        try stdout.print("Usage: maze-generator [option [value]]\n", .{});
        try stdout.print("Options:\n", .{});
        try stdout.print("  --help, -h          Show this help message\n", .{});
        try stdout.print("  --width <value>     Set the width of the maze (default: {d})\n", .{width});
        try stdout.print("  --height <value>    Set the height of the maze (default: {d})\n", .{height});
        try stdout.print("  --seed <value>      Set the random seed (default: random)\n", .{});
        try stdout.print("  --hardness <value>  Set the hardness level (min: 0, max: 255, default: {d})\n", .{hardness});
        try stdout.flush();
        return;
    }

    width = opts.width orelse width;
    height = opts.height orelse height;
    hardness = opts.hardness orelse hardness;

    if (opts.seed) |s| {
        seed = s;
    } else {
        var rng = initRng(null);
        seed = rng.random().int(u64);
    }

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
