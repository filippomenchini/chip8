const std = @import("std");

pub const DISPLAY_WIDTH = 64;
pub const DISPLAY_HEIGHT = 32;

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
display: [DISPLAY_WIDTH * DISPLAY_HEIGHT]bool,
pc: u16,
i: u16,
stack: [16]u16,
sp: u8,
delay_timer: u8,
sound_timer: u8,
registers: [16]u8,
current_raw_instruction: u16,

pub fn init() @This() {
    var chip_8 = @This(){
        .memory = [_]u8{0} ** 4096,
        .display = [_]bool{false} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT),
        .pc = 0x200,
        .i = 0,
        .stack = [_]u16{0} ** 16,
        .sp = 0,
        .delay_timer = 0,
        .sound_timer = 0,
        .registers = [_]u8{0} ** 16,
        .current_raw_instruction = 0x0000,
    };

    for (FONTSET, 0..) |font, i| {
        chip_8.memory[0x50 + i] = font;
    }

    return chip_8;
}

pub fn loadROM(self: *@This(), path: []const u8) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    var buffer: [2000]u8 = undefined;
    _ = try file.readAll(&buffer);
    @memcpy(self.memory[512..2512], &buffer);
}

pub fn getDisplayBuffer(self: *const @This()) *const [DISPLAY_WIDTH * DISPLAY_HEIGHT]bool {
    return &self.display;
}

pub fn step(self: *@This()) !void {
    const instruction_raw = self.fetch();
    const instruction = try self.decode(instruction_raw);
    self.execute(instruction);
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

const Instruction = union(enum) {
    clearScreen,
    returnFromSubroutine,
    skipIfXEqualsNN: struct { vx: u4, value: u8 },
    skipIfXNotEqualsNN: struct { vx: u4, value: u8 },
    skipIfXEqualsY: struct { vx: u4, vy: u4 },
    logicAndMath: struct { vx: u4, vy: u4, type: u4 },
    skipIfXNotEqualsY: struct { vx: u4, vy: u4 },
    call: u12,
    jump: u12,
    setX: struct { register: u4, value: u8 },
    addX: struct { register: u4, value: u8 },
    setI: u12,
    draw: struct { vx: u4, vy: u4, value: u4 },
};

pub const DecodeError = error{InvalidInstruction};
fn decode(self: *@This(), raw: u16) DecodeError!Instruction {
    self.current_raw_instruction = raw;

    const op_code = getNibble(raw, 0);
    const x = getNibble(raw, 1);
    const y = getNibble(raw, 2);
    const n = getNibble(raw, 3);
    const nn = raw & 0x00FF;
    const nnn = raw & 0x0FFF;

    return switch (op_code) {
        0x0 => {
            if (raw == 0x00E0) return Instruction.clearScreen;
            if (raw == 0x00EE) return Instruction.returnFromSubroutine;
            unreachable;
        },
        0x1 => Instruction{ .jump = @truncate(nnn) },
        0x3 => Instruction{ .skipIfXEqualsNN = .{ .vx = x, .value = @truncate(nn) } },
        0x4 => Instruction{ .skipIfXNotEqualsNN = .{ .vx = x, .value = @truncate(nn) } },
        0x5 => Instruction{ .skipIfXEqualsY = .{ .vx = x, .vy = y } },
        0x2 => Instruction{ .call = @truncate(nnn) },
        0x6 => Instruction{ .setX = .{ .register = x, .value = @truncate(nn) } },
        0x7 => Instruction{ .addX = .{ .register = x, .value = @truncate(nn) } },
        0x8 => Instruction{ .logicAndMath = .{ .vx = x, .vy = y, .type = n } },
        0x9 => Instruction{ .skipIfXNotEqualsY = .{ .vx = x, .vy = y } },
        0xA => Instruction{ .setI = @truncate(nnn) },
        0xD => Instruction{ .draw = .{ .vx = x, .vy = y, .value = n } },
        else => {
            return DecodeError.InvalidInstruction;
        },
    };
}

fn clearDisplay(self: *@This()) void {
    self.display = [_]bool{false} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT);
}

fn getPixel(self: *@This(), x: u6, y: u5) bool {
    const index: u16 = @as(u16, y) * DISPLAY_WIDTH + x;
    return self.display[index];
}

fn togglePixel(self: *@This(), x: u6, y: u5) void {
    const index: u16 = @as(u16, y) * DISPLAY_WIDTH + x;
    self.display[index] = !self.display[index];
}

fn execute(self: *@This(), instruction: Instruction) void {
    switch (instruction) {
        .clearScreen => self.clearDisplay(),
        .jump => |address| {
            self.pc = address;
            return;
        },
        .call => |address| {
            self.stack[self.sp] = self.pc + 2;
            self.sp += 1;
            self.pc = address;
            return;
        },
        .returnFromSubroutine => {
            self.sp -= 1;
            self.pc = self.stack[self.sp];
            return;
        },
        .skipIfXEqualsNN => |data| {
            if (self.registers[data.vx] == data.value) {
                self.pc += 2;
            }
        },
        .skipIfXNotEqualsNN => |data| {
            if (self.registers[data.vx] != data.value) self.pc += 2;
        },
        .skipIfXEqualsY => |data| {
            if (self.registers[data.vx] == self.registers[data.vy]) self.pc += 2;
        },
        .logicAndMath => |data| {
            switch (data.type) {
                0 => self.registers[data.vx] = self.registers[data.vy],
                1 => self.registers[data.vx] = self.registers[data.vx] | self.registers[data.vy],
                2 => self.registers[data.vx] = self.registers[data.vx] & self.registers[data.vy],
                3 => self.registers[data.vx] = self.registers[data.vx] ^ self.registers[data.vy],
                4 => {
                    const result = @addWithOverflow(self.registers[data.vx], self.registers[data.vy]);
                    self.registers[data.vx] = result[0];
                    self.registers[0xF] = result[1];
                },
                5 => {
                    const result = @subWithOverflow(self.registers[data.vx], self.registers[data.vy]);
                    self.registers[data.vx] = result[0];
                    self.registers[0xF] = if (self.registers[data.vx] > self.registers[data.vy]) 1 else 0;
                },
                6 => {
                    self.registers[data.vx] >>= 1;
                    self.registers[0xF] = self.registers[data.vx] & 0x1;
                },
                7 => {
                    const result = @subWithOverflow(self.registers[data.vy], self.registers[data.vx]);
                    self.registers[data.vx] = result[0];
                    self.registers[0xF] = if (self.registers[data.vy] > self.registers[data.vx]) 1 else 0;
                },
                0xE => {
                    self.registers[data.vx] <<= 1;
                    self.registers[0xF] = (self.registers[data.vx] & 0x80) >> 7;
                },
                else => unreachable,
            }
        },
        .skipIfXNotEqualsY => |data| {
            if (self.registers[data.vx] != self.registers[data.vy]) self.pc += 2;
        },
        .addX => |data| {
            const result = @addWithOverflow(self.registers[data.register], data.value);
            self.registers[data.register] = result[0];
        },
        .setI => |i| self.i = i,
        .setX => |data| self.registers[data.register] = data.value,
        .draw => |data| {
            const x = self.registers[data.vx] & (DISPLAY_WIDTH - 1);
            const y = self.registers[data.vy] & (DISPLAY_HEIGHT - 1);

            self.registers[0xF] = 0;

            for (0..data.value) |i| {
                const current_y = y + i;
                const sprite = self.memory[self.i + i];

                for (0..8) |j| {
                    const pixel_bit = (sprite >> (7 - @as(u3, @intCast(j)))) & 1;
                    const current_x = x + j;

                    if (pixel_bit != 0) {
                        if (current_x < DISPLAY_WIDTH and current_y < DISPLAY_HEIGHT) {
                            const screen_pixel_was_on = self.getPixel(
                                @truncate(current_x),
                                @truncate(current_y),
                            );

                            self.togglePixel(
                                @truncate(current_x),
                                @truncate(current_y),
                            );

                            if (screen_pixel_was_on) {
                                self.registers[0xF] = 1;
                            }
                        }
                    }
                }
            }
        },
    }

    self.pc += 2;
}
