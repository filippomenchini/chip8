rows: [64]bool,
cols: [32]bool,

pub fn init() @This() {
    return @This(){
        .rows = [_]bool{false} ** 64,
        .cols = [_]bool{false} ** 32,
    };
}
