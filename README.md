# Assembler_2sem
Assembler programs in MS DOS of 2 term MIPT

## Installing
1. Full setup of Dos-Box+Volkov-Commander+Asm: [ded32.net.ru/storage.ded32.ru/Materials/TXLib/dosbox-asm-setup.rar.exe](http://nas.ded32.ru/storage.ded32.ru/Materials/TXLib/dosbox-asm-setup.rar.exe)
2. Emulator of DosBox+Asm by yourself

---

## Frame Drawer
### Overview
This program draws a frame with specified parameters. It takes command-line arguments to define the frame dimensions, border style, and position.

### Usage
Run the program with the following syntax:
```sh
frame.com <width> <height> <border_color> <background_color> <position>
```
Example:
```sh
frame.com 30 5 4e 4 ddlx
```
This command creates a frame with a width of 30 characters, a height of 5, a border color of 4e, and a background color of 4, positioned at `ddlx`.

### Features
- Customizable width and height
- Changeable border and background color
- Adjustable position on screen

### Screenshot
![Frame Drawer Example](image.png)

---

## Resident Frame
### Overview
This program is written in assembly language for MS-DOS (TASM assembler). It is a resident program that intercepts interrupts `int 08h` (real-time clock) and `int 09h` (keyboard) and displays a frame showing the values of 8 registers: `AX, BX, CX, DX, SI, DI, BP, SP`.

### Usage
After launching this program, you can perform any DOS tasks, as it will run in the background. Press:
- `F1` to display the frame
- `F2` to hide it

### Unloading After Use
Don't forget to unload this program after use. You can do this by pressing `Alt + F5`. In the displayed list, select this program (marked with a dot on the left) and press **Update**.

### Features
- Uses double buffering to maintain screen integrity when toggling the frame
- Minimal performance impact while running in the background

### Known Issues
- If you enter multiple commands in the command line (causing scrolling) and then press `J`, the image may display incorrectly (classified as undefined behavior). This issue is under investigation.

---

## Author
[Your GitHub Profile](https://github.com/your-profile)

