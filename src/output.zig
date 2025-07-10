pub const DISPLAY_WIDTH = 64;
pub const DISPLAY_HEIGHT = 32;

const Output = @This();
display: [DISPLAY_WIDTH * DISPLAY_HEIGHT]bool,

pub fn init() Output {
    return .{
        .display = [_]bool{false} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT),
    };
}

pub fn getPixel(self: *const Output, x: u6, y: u5) bool {
    const index: u16 = @as(u16, y) * DISPLAY_WIDTH + x;
    return self.display[index];
}

pub fn togglePixel(self: *Output, x: u6, y: u5) void {
    const index: u16 = @as(u16, y) * DISPLAY_WIDTH + x;
    self.display[index] = !self.display[index];
}

pub fn getDisplayBuffer(self: *const Output) *const [DISPLAY_WIDTH * DISPLAY_HEIGHT]bool {
    return &self.display;
}

pub fn clearDisplay(self: *Output) void {
    self.display = [_]bool{false} ** (DISPLAY_WIDTH * DISPLAY_HEIGHT);
}
