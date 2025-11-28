const std = @import("std");
const getProcessArgs = @import("utils.zig").getProcessArgs;
const Rng = @import("utils.zig").Rng;
const Options = @import("options.zig").Options;
const generator = @import("generator/generator.zig");
const GenerationAlgorithm = @import("generator/types.zig").Algorithm;
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

    // Default parameters
    var width: isize = 20;
    var height: isize = 20;
    var hardness: u8 = 100;
    var seed: u64 = 0;
    var file_path: []const u8 = "maze.txt";
    var algorithm: GenerationAlgorithm = .growing_tree;
    var thread_count: usize = 1;

    // Parse command line arguments
    var process_args = try getProcessArgs(allocator);
    defer process_args.deinit(allocator);
    const opts = try Options.parse(process_args.items);

    if (opts.help) {
        try stdout.print("Usage: maze_generator [option [value]]\n", .{});
        try stdout.print("Options:\n", .{});
        try stdout.print("  --help, -h              Show this help message\n", .{});
        try stdout.print("  --width, -W <value>     Set the width of the maze (default: {d})\n", .{width});
        try stdout.print("  --height, -H <value>    Set the height of the maze (default: {d})\n", .{height});
        try stdout.print("  --seed, -s <value>      Set the random seed (default: random)\n", .{});
        try stdout.print("  --level, -l <level>     Set the hardness level (default: {d})\n", .{hardness});
        try stdout.print("                          Possible values: {d}-{d}\n", .{ 0, std.math.maxInt(u8) });
        try stdout.print("  --algorithm, -a <name>  Set the generation algorithm (default: {s})\n", .{@tagName(algorithm)});
        try stdout.print("                          Available algorithms:", .{});
        for (std.meta.tags(GenerationAlgorithm)) |alg| {
            try stdout.print(" {s}", .{@tagName(alg)});
        }
        try stdout.print("\n", .{});
        try stdout.print("  --output, -o <path>     Set the output file path (default: {s})\n", .{file_path});
        try stdout.print("  --threads, -t <value>   Set the number of threads to use (default: {d})\n", .{thread_count});
        try stdout.flush();
        return;
    }

    width = opts.width orelse width;
    height = opts.height orelse height;
    hardness = opts.hardness orelse hardness;
    file_path = opts.output orelse file_path;
    thread_count = opts.thread_count orelse thread_count;

    if (opts.seed) |s| {
        seed = s;
    } else {
        var rng = Rng.init(null);
        seed = rng.int(u64);
    }

    if (opts.algorithm) |alg_str| {
        if (std.meta.stringToEnum(GenerationAlgorithm, alg_str)) |alg| {
            algorithm = alg;
        } else {
            try stdout.print("Unknown algorithm: {s}, default will be used\n", .{alg_str});
            try stdout.flush();
        }
    }

    try stdout.print("Generating maze: {d}x{d}\n", .{ width, height });
    try stdout.print("Using hardness level: {d}\n", .{hardness});
    try stdout.print("Using seed: {d}\n", .{seed});
    try stdout.print("Using algorithm: {s}\n", .{@tagName(algorithm)});
    try stdout.flush();

    // Create an empty maze
    var maze = try Maze.init(allocator, width, height);
    defer maze.deinit();

    // Generate walls
    const start_time = std.time.milliTimestamp();
    try generator.generate(&maze, .{ .seed = seed, .hardness = hardness, .algorithm = algorithm, .thread_count = thread_count });
    const end_time = std.time.milliTimestamp();
    const duration = end_time - start_time;
    try stdout.print("Generation complete in: {d}ms\n", .{duration});
    try stdout.flush();

    try stdout.print("Writing to file: {s}\n", .{file_path});
    try stdout.flush();

    // Write maze to file
    try Writer.writeToFile(&maze, file_path);

    try stdout.print("Done\n", .{});
    try stdout.flush();
}
