# Remote-Virtual-Joystick

## This is made for personal and educational purposes only, there will be no updates and bug fixing

### Made in Godot 3.5.1

A virtual xbox360 joystick emulator, you put the client in a mobile phone(only tested on android) and open the server on the pc. Python server uses TCP, and the godot server uses UDP. 

Python server uses _websockets_ and _vgamepad_ modules

Godot server uses ViGEm library and I coded a simple interface(as a GDNative module) to press buttons and change the joystick state. You have to compile ViGEm first(as DLL) and then compile the GDNative module, its a simple process for anyone who worked with C/C++ so I am not gonna get deeper then this.