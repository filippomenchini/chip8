const Chip8 = @import("chip_8.zig");
const CPU = @import("cpu.zig");
const Memory = @import("memory.zig");

pub const CPUInfo = struct {
    pc: *const u16,
    sp: *const u8,
    i: *const u16,
    regs: *const [16]u8,
    stack: *const [16]u16,
    state: *const CPU.State,
};

pub const MemoryInfo = struct {
    ram: *const [Memory.RAM_SIZE]u8,
};

pub const InputInfo = struct {
    keypad: *const [16]bool,
};

const Debugger = @This();
chip_8: *const Chip8,

pub fn init(chip_8: *Chip8) Debugger {
    return .{
        .chip_8 = chip_8,
    };
}

pub fn getCpuInfo(self: *const Debugger) CPUInfo {
    return .{
        .pc = &self.chip_8.cpu.pc,
        .sp = &self.chip_8.cpu.sp,
        .i = &self.chip_8.cpu.i,
        .regs = &self.chip_8.cpu.regs,
        .stack = &self.chip_8.cpu.stack,
        .state = &self.chip_8.cpu.state,
    };
}

pub fn getMemoryInfo(self: *const Debugger) MemoryInfo {
    return .{
        .ram = &self.chip_8.memory.ram,
    };
}

pub fn getInputInfo(self: *const Debugger) InputInfo {
    return .{
        .keypad = &self.chip_8.input.keypad,
    };
}
