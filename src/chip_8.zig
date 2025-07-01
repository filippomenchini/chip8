const Display = @import("display.zig");

const Instruction = union(enum) {
    clearScreen,
    jump: u12,
    setX: struct { register: u4, value: u8 },
    addX: struct { register: u4, value: u8 },
    setI: u12,
    draw: struct { vx: u4, vy: u4, value: u4 },
};

const FONTSET = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

memory: [4096]u8,
display: Display,
pc: u16,
i: u16,
stack: [16]u16,
sp: u8,
delay_timer: u8,
sound_timer: u8,
registers: [16]u8,

pub fn init() @This() {
    var chip_8 = @This(){
        .memory = [_]u8{0} ** 4096,
        .display = Display.init(),
        .pc = 0x200,
        .i = 0,
        .stack = [_]u16{0} ** 16,
        .sp = 0,
        .delay_timer = 0,
        .sound_timer = 0,
        .registers = [_]u8{0} ** 16,
    };

    for (FONTSET, 0..) |font, i| {
        chip_8.memory[0x50 + i] = font;
    }

    return chip_8;
}

fn fetch(self: *@This()) u16 {
    const first_byte = @as(u16, self.memory[self.pc]);
    const second_byte = self.memory[self.pc + 1];

    return (first_byte << 8) | second_byte;
}

fn getNibble(raw: u16, position: u2) u4 {
    const shift = @as(u4, 3 - position) * 4;
    return @truncate((raw >> shift) & 0xF);
}

const DecodeError = error{InvalidInstruction};
fn decode(raw: u16) DecodeError!Instruction {
    if (raw == 0x00E0) return Instruction.clearScreen;

    const op_code = getNibble(raw, 0);
    const x = getNibble(raw, 1);
    const y = getNibble(raw, 2);
    const n = getNibble(raw, 3);
    const nn = raw & 0x00FF;
    const nnn = raw & 0x0FFF;

    return switch (op_code) {
        0x1 => Instruction{ .jump = nnn },
        0x6 => Instruction{ .setX = .{ .register = x, .value = nn } },
        0x7 => Instruction{ .addX = .{ .register = x, .value = nn } },
        0xA => Instruction{ .setI = nnn },
        0xD => Instruction{ .draw = .{ .vx = x, .vy = y, .value = n } },
        else => DecodeError.InvalidInstruction,
    };
}
