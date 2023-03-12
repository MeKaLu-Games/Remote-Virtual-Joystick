#include "libvigem.h"

#include <cmath>

using namespace godot;

const XUSB_REPORT LibVigem::get_default_report() {
    return XUSB_REPORT {
        // USHORT wButtons;
        // BYTE bLeftTrigger;
        // BYTE bRightTrigger;
        // SHORT sThumbLX;
        // SHORT sThumbLY;
        // SHORT sThumbRX;
        // SHORT sThumbRY;
        0, 0, 0, 0, 0, 0, 0,        
    };
}

void LibVigem::_register_methods() {
    register_method("_init", &LibVigem::_init);
    register_method("_exit_tree", &LibVigem::_exit_tree);
    
    register_method("connect_device", &LibVigem::connect_device);
    register_method("disconnect_device", &LibVigem::disconnect_device);

    register_method("update", &LibVigem::update);
    register_method("reset", &LibVigem::reset);

    register_method("button_a", &LibVigem::button_a);
    register_method("button_b", &LibVigem::button_b);
    register_method("button_x", &LibVigem::button_x);
    register_method("button_y", &LibVigem::button_y);

    register_method("left_joystick", &LibVigem::left_joystick);
    register_method("right_joystick", &LibVigem::right_joystick);
}

LibVigem::LibVigem() {
}

LibVigem::~LibVigem() {
}

void LibVigem::_init() {
//    Godot::print("hello");
    this->client = vigem_alloc();

    if (this->client == nullptr) {
        Godot::print("failed to allocate vigem");
        return;
    }
    
    const auto retval = vigem_connect(this->client);

    if (!VIGEM_SUCCESS(retval)) {
        Godot::print("ViGEm Bus connection failed");
        return; 
    }
}

void LibVigem::_exit_tree() {
    vigem_disconnect(this->client);
    vigem_free(this->client);
}

bool LibVigem::connect_device() {
    this->pad = vigem_target_x360_alloc();

    const auto pir = vigem_target_add(this->client, this->pad);

    if (!VIGEM_SUCCESS(pir)) {
        Godot::print("Target plugin failed");
        return false;
    }

    XInputGetState(0, &this->state);
    
    this->reset();
    this->update();
    //vigem_target_x360_update(this->client, this->pad, *reinterpret_cast<XUSB_REPORT*>(&this->state.Gamepad));

    return true;
}

void LibVigem::disconnect_device() {
    vigem_target_remove(this->client, this->pad);
    vigem_target_free(this->pad);
}

void LibVigem::update() {
    if (!vigem_target_x360_update(this->client, this->pad, this->report)) {
        Godot::print("X360 (virtual)device failed to update");
    }
}

void LibVigem::reset() {
    this->report = get_default_report();
}

void LibVigem::button_a(bool is_pressed) {
    if (is_pressed) this->report.wButtons = this->report.wButtons | XUSB_GAMEPAD_A;
    else this->report.wButtons = this->report.wButtons & ~XUSB_GAMEPAD_A;
}

void LibVigem::button_b(bool is_pressed) {
    if (is_pressed) this->report.wButtons = this->report.wButtons | XUSB_GAMEPAD_B;
    else this->report.wButtons = this->report.wButtons & ~XUSB_GAMEPAD_B;
}

void LibVigem::button_x(bool is_pressed) {
    if (is_pressed) this->report.wButtons = this->report.wButtons | XUSB_GAMEPAD_X;
    else this->report.wButtons = this->report.wButtons & ~XUSB_GAMEPAD_X;
}

void LibVigem::button_y(bool is_pressed) {
    if (is_pressed) this->report.wButtons = this->report.wButtons | XUSB_GAMEPAD_Y;
    else this->report.wButtons = this->report.wButtons & ~XUSB_GAMEPAD_Y;
}

void LibVigem::left_joystick(float x, float y) {
    this->report.sThumbLX = static_cast<SHORT>(std::round(x * 32767));
    this->report.sThumbLY = static_cast<SHORT>(std::round(y * 32767));
}

void LibVigem::right_joystick(float x, float y) {
    this->report.sThumbRX = static_cast<SHORT>(std::round(x * 32767));
    this->report.sThumbRY = static_cast<SHORT>(std::round(y * 32767));
}
