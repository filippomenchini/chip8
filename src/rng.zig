const std = @import("std");

const RNG = @This();
prng: std.rand.DefaultPrng,

pub fn init() RNG {
    return RNG{
        .prng = std.rand.DefaultPrng.init(@bitCast(std.time.milliTimestamp())),
    };
}

pub fn next(self: *RNG) u8 {
    return self.prng.random().int(u8);
}

pub fn setSeed(self: *RNG, seed: u64) void {
    self.prng = std.rand.DefaultPrng.init(seed);
}
