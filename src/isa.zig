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
