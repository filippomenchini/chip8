const std = @import("std");

const CPU = @import("cpu.zig");
const Memory = @import("memory.zig");
const Output = @import("output.zig");
const Input = @import("input.zig");
const Timer = @import("timer.zig");
const RNG = @import("rng.zig");
const Clock = @import("clock.zig");
const ISA = @import("isa.zig");

const CPU_CLOCK_HZ = 600;
const TIMER_CLOCK_HZ = 60;

pub const DISPLAY_WIDTH = Output.DISPLAY_WIDTH;
pub const DISPLAY_HEIGHT = Output.DISPLAY_HEIGHT;

const Chip8 = @This();
cpu: CPU,
memory: Memory,
output: Output,
input: Input,
delay_timer: Timer,
sound_timer: Timer,
rng: RNG,
cpu_clock: Clock,
timer_clock: Clock,
current_raw_instruction: u16,

pub fn init() Chip8 {
    return .{
        .cpu = CPU.init(),
        .memory = Memory.init(),
        .output = Output.init(),
        .input = Input.init(),
        .delay_timer = Timer.init(),
        .sound_timer = Timer.init(),
        .rng = RNG.init(),
        .cpu_clock = Clock.init(CPU_CLOCK_HZ),
        .timer_clock = Clock.init(TIMER_CLOCK_HZ),
        .current_raw_instruction = 0x0,
    };
}

pub fn loadROM(self: *Chip8, path: []const u8) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    if (file_size > 2000) {
        return error.ROMTooLarge;
    }

    var buffer: [2000]u8 = undefined;
    const bytes_read = try file.readAll(&buffer);

    for (0..bytes_read) |i| {
        self.memory.write(0x200 + @as(u16, @intCast(i)), buffer[i]);
    }
}

pub fn step(self: *Chip8) !void {
    if (self.cpu_clock.shouldTick()) {
        const raw_instruction = self.cpu.fetch(&self.memory);
        self.current_raw_instruction = raw_instruction;

        const instruction = ISA.decode(raw_instruction);
        try ISA.execute(
            instruction,
            &self.cpu,
            &self.memory,
            &self.input,
            &self.output,
            &self.delay_timer,
            &self.sound_timer,
            &self.rng,
        );
    }

    if (self.timer_clock.shouldTick()) {
        self.delay_timer.update();
        self.sound_timer.update();
    }
}

pub fn getDisplayBuffer(self: *const Chip8) *const [DISPLAY_WIDTH * DISPLAY_HEIGHT]bool {
    return self.output.getDisplayBuffer();
}

pub fn isBeeping(self: *const Chip8) bool {
    return self.sound_timer.get() > 0;
}

pub fn setKey(self: *Chip8, key: u4, pressed: bool) void {
    self.input.setKey(key, pressed);
}

pub fn getKey(self: *const Chip8, key: u4) bool {
    return self.input.getKey(key);
}
