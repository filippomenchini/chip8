const std = @import("std");
const rl = @import("raylib");
const Chip8 = @import("chip_8.zig");

const PIXEL_SCALE = 25;

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
        chip8.step() catch |err| {
            if (err == Chip8.DecodeError.InvalidInstruction) {
                std.debug.print("Invalid instruction: 0x{X} at PC: 0x{X}\n", .{ chip8.current_raw_instruction, chip8.pc });
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
