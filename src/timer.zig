const Timer = @This();

timer: u8,

pub fn init() Timer {
    return .{
        .timer = 0,
    };
}

pub fn update(self: *Timer) void {
    if (self.timer == 0) return;
    self.timer -= 1;
}

pub fn get(self: *Timer) u8 {
    return self.timer;
}

pub fn set(self: *Timer, value: u8) void {
    self.timer = value;
}
