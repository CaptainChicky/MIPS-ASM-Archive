## What is this?
MIPS assembly program examples, with comprehensive comments/documentation.

Assemble and run the code in a suitable MIPS assembler, such as via https://github.com/CaptainChicky/Java-MIPS-Assembler.

Do note that although registers are declared with a dollar sign `$t0`, most of the time I omit them for convenience `t0`, and the aforementioned assembler I linked is able to interpret both fine.

## How to Run
Other than the basic register demo, all other code examples require the "Keyboard and LED Display Simulator" tool to be connected.

You load the program into the MIPS assembler, assemble it, then connect the "Keyboard and LED Display Simulator" tool if needed, and then click run. You will be seeing text in the console, visuals in the simulator tool, or both. 

## Overview
The 5 programs are as follows:
<ol>
    <li> Basic Register Demo: An introduction to MIPS assembly console, registers and all. Interaction is purely via console.
    <li> Drawing Demo: An interactive pixel drawing application that you draw via console inputs. Interaction is via console commands (c/p/l/r/q) and see results rendered in the display simulator.
    <li> Tilemap Editor: A tile map editor of a 16×16 grid of tiles. Interaction directly via display using Z/X/C/V and arrow keys.
    <li> Particle System: A visual particle fountain effect with basic physics simulation. Click-and-hold to spawn particles continuously.
    <li> Breakout: A complete Breakout/Arkanoid game implementation. Mouse-controlled paddle with boundary clamping and uses trigonometric bounce calculations using lookup tables to bounce ball.
</ol>