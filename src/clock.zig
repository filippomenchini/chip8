const std = @import("std");

const Clock = @This();
frequency_hz: u32,
last_tick: i64,
accumulator: f64,

pub fn init(frequency_hz: u32) Clock {
    return Clock{
        .frequency_hz = frequency_hz,
        .last_tick = std.time.milliTimestamp(),
        .accumulator = 0.0,
    };
}

pub fn shouldTick(self: *Clock) bool {
    const now = std.time.milliTimestamp();
    const delta_ms = @as(f64, @floatFromInt(now - self.last_tick));
    self.last_tick = now;

    const period_ms = 1000.0 / @as(f64, @floatFromInt(self.frequency_hz));
    self.accumulator += delta_ms;

    if (self.accumulator >= period_ms) {
        self.accumulator -= period_ms;
        return true;
    }
    return false;
}
