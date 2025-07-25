const Memory = @import("memory.zig");

pub const State = union(enum) {
    running,
    waiting: u4,
};

const CPU = @This();
pc: u16,
sp: u8,
i: u16,
regs: [16]u8,
stack: [16]u16,
state: State,

pub fn init() CPU {
    return .{
        .pc = 0x200,
        .i = 0,
        .stack = [_]u16{0} ** 16,
        .sp = 0,
        .regs = [_]u8{0} ** 16,
        .state = .running,
    };
}

pub fn fetch(self: *CPU, memory: *const Memory) u16 {
    const first_byte = @as(u16, memory.read(self.pc));
    const second_byte = memory.read(self.pc + 1);
    self.pc += 2;

    return (first_byte << 8) | second_byte;
}

pub fn jump(self: *CPU, address: u16) void {
    self.pc = address;
}

pub fn call(self: *CPU, address: u16) void {
    self.stack[self.sp] = self.pc;
    self.sp += 1;
    self.pc = address;
}

pub fn ret(self: *CPU) void {
    self.sp -= 1;
    self.pc = self.stack[self.sp];
}
