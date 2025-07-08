const RAM_SIZE = 4096;
const Memory = @This();

ram: [RAM_SIZE]u8,

pub fn init() Memory {
    return .{
        .ram = [_]u8{0} ** RAM_SIZE,
    };
}

pub fn read(self: *Memory, address: u16) u8 {
    return self.ram[address];
}

pub fn write(self: *Memory, address: u16, value: u8) void {
    self.ram[address] = value;
}
