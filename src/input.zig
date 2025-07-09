const Input = @This();

keypad: [16]bool,

pub fn getKey(self: *Input, key: u4) bool {
    return self.keypad[key];
}

pub fn setKey(self: *Input, key: u4, value: bool) void {
    self.keypad[key] = value;
}
