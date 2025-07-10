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
    try chip8.loadROM("./breakout.ch8");

    rl.setTraceLogLevel(.none);

    const window_width = Chip8.DISPLAY_WIDTH * PIXEL_SCALE;
    const window_height = Chip8.DISPLAY_HEIGHT * PIXEL_SCALE;

    rl.initWindow(window_width, window_height, "CHIP-8 Emulator");
    defer rl.closeWindow();

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    var beep_sound: ?rl.Sound = null;
    var is_playing = false;

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        updateInput(&chip8);

        chip8.step() catch |err| {
            std.debug.print("Emulator error: {}\n", .{err});
            break;
        };

        if (chip8.isBeeping() and !is_playing) {
            if (beep_sound == null) {
                beep_sound = rl.loadSound("beep.wav") catch |err| {
                    std.debug.print("Could not load beep.wav: {}\n", .{err});
                    continue;
                };
            }
            if (beep_sound) |sound| {
                rl.playSound(sound);
            }
            is_playing = true;
        } else if (!chip8.isBeeping()) {
            is_playing = false;
        }

        renderFrame(&chip8);
    }

    if (beep_sound) |sound| {
        rl.unloadSound(sound);
    }
}

fn updateInput(chip8: *Chip8) void {
    for (KEY_MAPPING, 0..) |raylib_key, chip8_key| {
        const pressed = rl.isKeyDown(raylib_key);
        chip8.setKey(@intCast(chip8_key), pressed);
    }
}

fn renderFrame(chip8: *Chip8) void {
    rl.beginDrawing();
    defer rl.endDrawing();

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
}
