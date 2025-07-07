const std = @import("std");
const rl = @import("raylib");
const Chip8 = @import("chip_8.zig");

const PIXEL_SCALE = 25;

const KEY_MAPPING = [_]rl.KeyboardKey{
    rl.KeyboardKey.x, // 0
    rl.KeyboardKey.one, // 1
    rl.KeyboardKey.two, // 2
    rl.KeyboardKey.three, // 3
    rl.KeyboardKey.q, // 4
    rl.KeyboardKey.w, // 5
    rl.KeyboardKey.e, // 6
    rl.KeyboardKey.a, // 7
    rl.KeyboardKey.s, // 8
    rl.KeyboardKey.d, // 9
    rl.KeyboardKey.z, // A
    rl.KeyboardKey.c, // B
    rl.KeyboardKey.four, // C
    rl.KeyboardKey.r, // D
    rl.KeyboardKey.f, // E
    rl.KeyboardKey.v, // F
};

pub fn main() !void {
    var chip8 = Chip8.init();
    try chip8.loadROM("./test_opcode.ch8");

    rl.setTraceLogLevel(.none);

    const window_width = Chip8.DISPLAY_WIDTH * PIXEL_SCALE;
    const window_height = Chip8.DISPLAY_HEIGHT * PIXEL_SCALE;

    rl.initWindow(window_width, window_height, "CHIP-8 Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        for (KEY_MAPPING, 0..) |raylib_key, chip8_key| {
            chip8.keypad[chip8_key] = rl.isKeyDown(raylib_key);
        }

        chip8.step() catch |err| {
            if (err == Chip8.DecodeError.InvalidInstruction) {
                std.debug.print("Invalid instruction: 0x{X} at PC: 0x{X}\n", .{ chip8.current_raw_instruction, chip8.pc });
            } else if (err == Chip8.ExecuteError.InvalidSubOpcode) {
                std.debug.print("Invalid sub opcode: 0x{X} at PC: 0x{X}\n", .{ chip8.current_raw_instruction, chip8.pc });
            } else {
                std.debug.print("Error: {}\n", .{err});
            }
            break;
        };

        // Uncomment for debugging
        // std.debug.print("Running instruction: 0x{X} at PC: 0x{X}\n", .{ chip8.current_raw_instruction, chip8.pc });

        rl.beginDrawing();
        rl.clearBackground(.black);

        const buffer = chip8.getDisplayBuffer();

        for (0..Chip8.DISPLAY_HEIGHT) |y| {
            for (0..Chip8.DISPLAY_WIDTH) |x| {
                const pixel_index = y * Chip8.DISPLAY_WIDTH + x;
                if (buffer[pixel_index]) {
                    rl.drawRectangle(
                        @intCast(x * PIXEL_SCALE),
                        @intCast(y * PIXEL_SCALE),
                        PIXEL_SCALE,
                        PIXEL_SCALE,
                        .white,
                    );
                }
            }
        }

        rl.endDrawing();
    }
}
