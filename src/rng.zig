const std = @import("std");

const RNG = @This();
prng: std.Random.DefaultPrng,

pub fn init() RNG {
    return RNG{
        .prng = std.Random.DefaultPrng.init(@bitCast(std.time.milliTimestamp())),
    };
}

pub fn next(self: *RNG) u8 {
    return self.prng.random().int(u8);
}
