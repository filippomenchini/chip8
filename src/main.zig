const std = @import("std");
const rl = @import("raylib");
const Chip8 = @import("chip_8.zig");

pub fn main() !void {
    _ = Chip8.init();
    rl.initWindow(640, 320, "CHIP-8 Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(.black);
        rl.drawText("Hello CHIP-8!", 0, 0, 24, .white);
        rl.endDrawing();
    }
}
