const CPU = @import("cpu.zig");
const Memory = @import("memory.zig");
const Input = @import("input.zig");
const Output = @import("output.zig");
const RNG = @import("rng.zig");

const rng = RNG.init();

pub const Instruction = struct {
    op_code: u4,
    vx: u4,
    vy: u4,
    n: u4,
    nn: u8,
    nnn: u12,
};

pub fn decode(raw: u16) Instruction {
    return .{
        .op_code = @truncate((raw & 0xF000) >> 12),
        .vx = @truncate((raw & 0x0F00) >> 8),
        .vy = @truncate((raw & 0x00F0) >> 4),
        .n = @truncate(raw & 0x000F),
        .nn = @truncate(raw & 0x00FF),
        .nnn = @truncate(raw & 0x0FFF),
    };
}

pub const IsaExecutionError = error{ InvalidOpCode, InvalidSubOpCode };
pub fn execute(instruction: Instruction, cpu: *CPU, memory: *Memory, input: *Input, output: *Output) IsaExecutionError!void {
    switch (instruction.op_code) {
        0x0 => switch (instruction.nnn) {
            0x0E0 => output.clearDisplay(),
            0x0EE => cpu.ret(),
        },
        0x1 => cpu.jump(instruction.nnn),
        0x2 => cpu.ret(),
        0x3 => if (cpu.regs[instruction.vx] == instruction.nn) {
            cpu.pc += 2;
        },
        0x4 => if (cpu.regs[instruction.vx] != instruction.nn) {
            cpu.pc += 2;
        },
        0x5 => if (cpu.regs[instruction.vx] != cpu.regs[instruction.vy]) {
            cpu.pc += 2;
        },
        0x6 => cpu.regs[instruction.vx] = instruction.nn,
        0x7 => cpu.regs[instruction.vx] +%= instruction.nn,
        0x8 => switch (instruction.n) {
            0x0 => cpu.regs[instruction.vx] = cpu.regs[instruction.vy],
            0x1 => cpu.regs[instruction.vx] = cpu.regs[instruction.vx] | cpu.regs[instruction.vy],
            0x2 => cpu.regs[instruction.vx] = cpu.regs[instruction.vx] & cpu.regs[instruction.vy],
            0x3 => cpu.regs[instruction.vx] = cpu.regs[instruction.vx] ^ cpu.regs[instruction.vy],
            0x4 => {
                const result = @addWithOverflow(cpu.regs[instruction.vx], cpu.regs[instruction.vy]);
                cpu.regs[instruction.vx] = result[0];
                cpu.regs[0xF] = result[1];
            },
            0x5 => {
                const vx = cpu.regs[instruction.vx];
                const vy = cpu.regs[instruction.vy];
                const result = @subWithOverflow(vx, vy);
                cpu.regs[instruction.vx] = result[0];
                cpu.regs[0xF] = if (vx >= vy) 1 else 0;
            },
            0x6 => {
                cpu.regs[0xF] = cpu.regs[instruction.vx] & 0x1;
                cpu.regs[instruction.vx] >>= 1;
            },
            0x7 => {
                const vx = cpu.regs[instruction.vx];
                const vy = cpu.regs[instruction.vy];
                const result = @subWithOverflow(vy, vx);
                cpu.regs[instruction.vx] = result[0];
                cpu.regs[0xF] = if (vy >= vx) 1 else 0;
            },
            0xE => {
                cpu.regs[0xF] = (cpu.regs[instruction.vx] & 0x80) >> 7;
                cpu.regs[instruction.vx] <<= 1;
            },
            else => return IsaExecutionError.InvalidSubOpCode,
        },
        0x9 => if (cpu.regs[instruction.vx] != cpu.regs[instruction.vy]) {
            cpu.pc += 2;
        },
        0xA => cpu.i = instruction.nnn,
        0xB => cpu.pc = instruction.nnn + cpu.regs[0x0],
        0xC => {
            const random_value = rng.next();
            cpu.regs[instruction.vx] = random_value & instruction.nn;
        },
        0xD => {
            const x = cpu.regs[instruction.vx] & (Output.DISPLAY_WIDTH - 1);
            const y = cpu.regs[instruction.vy] & (Output.DISPLAY_HEIGHT - 1);

            cpu.regs[0xF] = 0;

            for (0..instruction.n) |i| {
                const current_y = y + i;
                const sprite = memory.read(cpu.i + i);

                for (0..8) |j| {
                    const pixel_bit = (sprite >> (7 - @as(u3, @intCast(j)))) & 1;
                    const current_x = x + j;

                    if (pixel_bit == 0) continue;
                    if (current_x > Output.DISPLAY_WIDTH or current_y > Output.DISPLAY_HEIGHT) continue;

                    const screen_pixel_was_on = output.getPixel(
                        @truncate(current_x),
                        @truncate(current_y),
                    );

                    output.togglePixel(
                        @truncate(current_x),
                        @truncate(current_y),
                    );

                    if (screen_pixel_was_on) {
                        cpu.registers[0xF] = 1;
                    }
                }
            }
        },
        0xE => switch (instruction.nn) {
            0x9E => {
                const key = cpu.regs[instruction.vx] & 0xF;
                if (input.getKey(key)) {
                    cpu.jump(cpu.pc + 2);
                }
            },
            0xA1 => {
                const key = cpu.regs[instruction.vx] & 0xF;
                if (input.getKey(key)) {
                    cpu.jump(cpu.pc + 2);
                }
            },
            else => return IsaExecutionError.InvalidSubOpCode,
        },
        0xF => {}, // TODO: implement 0xF instructions with new architecture
        else => return IsaExecutionError.InvalidOpCode,
    }
}
