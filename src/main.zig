const std = @import("std");
const rl = @import("raylib");
const Chip8 = @import("chip_8.zig");

pub fn main() !void {
    var chip8 = Chip8.init();

    rl.initWindow(640, 320, "CHIP-8 Emulator");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const pixel_scale = 10;

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
                        @intCast(x * pixel_scale),
                        @intCast(y * pixel_scale),
                        pixel_scale,
                        pixel_scale,
                        .white,
                    );
                }
            }
        }

        rl.endDrawing();
    }
}
