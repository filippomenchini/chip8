# CHIP-8 Emulator

A CHIP-8 emulator written in Zig with Raylib.

![Screenshot](screenshot.png)

All CHIP-8 instructions handled, sound is also working! :)

## Build and Run

```bash
zig build run
```

## Controls

```
1 2 3 C    →    1 2 3 4
4 5 6 D    →    Q W E R
7 8 9 E    →    A S D F
A 0 B F    →    Z X C V
```

The CHIP-8 keypad is mapped to QWERTY keys as shown above.

## To do
- [X] Basic CHIP-8 emulator
- [ ] Divide code into modules (CPU, Memory, Display, Instructions, Clock, etc...)
- [ ] Add a debugger (it should output the state of every module and give the ability to step through every instruction)
- [ ] Add SUPER-CHIP support
- [ ] Add XO-CHIP support
