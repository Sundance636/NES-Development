# NES Projects
This is just a work space showcase my tech demos and projects I wrote in 6502 Assembly for the NES (Nintendo Entertainment System).

## Usage
Each folder will have a `test` file (with no extension) which is the compiled game code from its corresponding `test.s` source file, so just open your prefered NES Emulator (<a href="https://fceux.com/web/home.html">FCEUX</a> Recommended) and start the selected ROM.

## Compiling Source Code

### Prerequisites
 + Visual Studio Code
 + ca65 macro assembler extension (from Visual Studio code)
 + cc65
 + FCEUX (Recommended)

 ### Guide
 Reference -> [This](https://www.youtube.com/watch?v=RtY5FV5TrIU&t=72s) <- for setting up the environment to write and compile the source code

**Linux**

Because the video guide uses Windows, here are some extra steps for linux users, use your package manager install the "cc65" package

**Arch distributions (Using AUR)**
```
yay cc65
```

**Installing FCEUX**
```
yay fceux
```
We must link the path to the compilers binaries in Visual Studio, because we are on linux the path 'C:\cc65\bin\cl65' as in the video will not work, and so instead, in your "cl65config.json" file we must make sure the "executable" property is set to the right path:

`"executable": "/usr/bin/cl65"` (if it was installed in this path)

OR

`"executable": "path/to/cl65"` (replace with where your path to cl65 is)

From there in your visual studio code workspace, configure the default build task selecting ca65 as the default task, then with CTRL + SHIFT + B compile and build the ROM.

## Resourses
These are some resoures I referenced a lot while developing.
 + [Nesdev Wiki](https://www.nesdev.org/wiki/Nesdev_Wiki)
 + [6502 Instruction set](http://www.6502.org/tutorials/6502opcodes.html)
 + [NESHacker YouTube Channel](https://www.youtube.com/@NesHacker/featured)
 +  [ca65 Users Guide](https://cc65.github.io/doc/ca65.html)
 +  [cc65](https://cc65.github.io/)
