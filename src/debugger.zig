const std = @import("std");

const Chip8 = @import("chip_8.zig");
const CPU = @import("cpu.zig");
const Memory = @import("memory.zig");
const Input = @import("input.zig");

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
cpu_info: ?CPUInfo,
memory_info: ?MemoryInfo,
input_info: ?InputInfo,

pub fn init() Debugger {
    return .{
        .cpu_info = null,
        .memory_info = null,
        .input_info = null,
    };
}

pub fn setCpuInfo(self: *Debugger, cpu: *const CPU) void {
    self.cpu_info = CPUInfo{
        .pc = &cpu.pc,
        .sp = &cpu.sp,
        .i = &cpu.i,
        .regs = &cpu.regs,
        .stack = &cpu.stack,
        .state = &cpu.state,
    };
}

pub fn setMemoryInfo(self: *Debugger, memory: *const Memory) void {
    self.memory_info = MemoryInfo{
        .ram = &memory.ram,
    };
}

pub fn setInputInfo(self: *Debugger, input: *const Input) void {
    self.input_info = InputInfo{
        .keypad = &input.keypad,
    };
}
