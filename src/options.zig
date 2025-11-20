const std = @import("std");

pub const Options = struct {
    width: ?isize,
    height: ?isize,
    seed: ?u64,
    hardness: ?u8,
    help: bool,

    pub fn parse(process_args: []const [:0]const u8) !Options {
        var options = Options{
            .width = null,
            .height = null,
            .seed = null,
            .hardness = null,
            .help = false,
        };

        var idx: usize = 0;
        while (idx < process_args.len) : (idx += 1) {
            const arg = process_args[idx];
            if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
                options.help = true;
            } else if (std.mem.startsWith(u8, arg, "--width")) {
                idx += 1;
                const value = process_args[idx];
                options.width = try std.fmt.parseInt(isize, value, 10);
            } else if (std.mem.startsWith(u8, arg, "--height")) {
                idx += 1;
                const value = process_args[idx];
                options.height = try std.fmt.parseInt(isize, value, 10);
            } else if (std.mem.startsWith(u8, arg, "--seed")) {
                idx += 1;
                const value = process_args[idx];
                options.seed = try std.fmt.parseInt(u64, value, 10);
            } else if (std.mem.startsWith(u8, arg, "--hardness")) {
                idx += 1;
                const value = process_args[idx];
                options.hardness = try std.fmt.parseInt(u8, value, 10);
            }
        }

        return options;
    }
};
