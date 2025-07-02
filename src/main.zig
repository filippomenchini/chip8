const std = @import("std");
const rl = @import("raylib");
const Chip8 = @import("chip_8.zig");

const PIXEL_SCALE = 25;

pub fn main() !void {
    var chip8 = Chip8.init();
    try chip8.loadROM("./IBM Logo.ch8");

    const window_width = Chip8.DISPLAY_WIDTH * PIXEL_SCALE;
    const window_height = Chip8.DISPLAY_HEIGHT * PIXEL_SCALE;
    rl.initWindow(window_width, window_height, "CHIP-8 Emulator");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        chip8.step() catch |err| {
            std.debug.print("Error: {}\n", .{err});
            continue;
        };

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
