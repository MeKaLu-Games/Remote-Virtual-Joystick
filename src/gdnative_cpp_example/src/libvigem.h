#ifndef LibVigem_H
#define LibVigem_H

#include <Godot.hpp>
#include <Node.hpp>
#include <GodotGlobal.hpp>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Xinput.h>
#include <ViGEm/Client.h>
#pragma comment(lib, "Xinput.lib")

namespace godot {

class LibVigem : public Node {
    GODOT_CLASS(LibVigem, Node)

protected:
    PVIGEM_CLIENT client;
    PVIGEM_TARGET pad;
    XINPUT_STATE state;
    XUSB_REPORT report;

protected:
    static const XUSB_REPORT get_default_report();

public:
    static void _register_methods();

    LibVigem();
    virtual ~LibVigem();

    void _init(); 
    void _exit_tree(); 

    bool connect_device();
    void disconnect_device();

    void update();
    void reset();

    void button_a(bool is_pressed);
    void button_b(bool is_pressed);
    void button_x(bool is_pressed);
    void button_y(bool is_pressed);

    // 0.0-1.0
    void left_joystick(float x, float y);
    void right_joystick(float x, float y);
};

}

#endif