pub const Algorithm = enum {
    growing_tree,
    patch_growing_tree,
};

pub const Config = struct {
    seed: u64,
    hardness: u8,
    algorithm: Algorithm,
    thread_count: usize,
};
