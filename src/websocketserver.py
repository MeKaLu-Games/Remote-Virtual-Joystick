import asyncio
import websockets
import utils
import math
import time
import vgamepad as vg

gamepad = vg.VX360Gamepad()
vibration_power = 3
vibration_large = 0
vibration_small = 0

def rumble_callback(client, target, large_motor, small_motor, led_number, user_data):
    """
    Callback function triggered at each received state change

    :param client: vigem bus ID
    :param target: vigem device ID
    :param large_motor: integer in [0, 255] representing the state of the large motor
    :param small_motor: integer in [0, 255] representing the state of the small motor
    :param led_number: integer in [0, 255] representing the state of the LED ring
    :param user_data: placeholder, do not use
    """
    # Do your things here. For instance:
    # print(f"Received notification for client {client}, target {target}")
    # print(f"large motor: {large_motor}, small motor: {small_motor}")
    # print(f"led number: {led_number}")

    global vibration_large
    global vibration_small
    vibration_large = large_motor * vibration_power
    vibration_small = small_motor * vibration_power

    #print(f"vibration LARGE: {vibration_large}")
    #print(f"vibration SMALL: {vibration_small}")

async def handler(websocket):
    stop = False

    trigger_x, trigger_y = 0, 0

    # wake up the device
    gamepad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
    gamepad.update()
    time.sleep(0.5)
    
    while True:
        try:
            message = await websocket.recv()
            data = utils.decode_data(f"{message}")
            #print(str(decoded))

            if len(data) == 1:
                if data[0] == "STOP": stop = True
                await websocket.send(f"VIBRATE:{200}")
                await websocket.send(message)
            elif len(data) == 2:
                if data[0] == "LEFT_JOYSTICK_X":
                    trigger_x = float(data[1])
                    gamepad.left_joystick_float(trigger_x, trigger_y)
                    await websocket.send(f"VIBRATE:{50}")
                    await websocket.send(message)
                elif data[0] == "LEFT_JOYSTICK_Y":
                    trigger_y = float(data[1])
                    gamepad.left_joystick_float(trigger_x, trigger_y)
                    await websocket.send(f"VIBRATE:{50}")
                    await websocket.send(message)
                elif data[0] == "HOLD":
                    await websocket.send(message)
                    if data[1] == 'A':
                        gamepad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                        await websocket.send(f"VIBRATE:{100}")
                    elif data[1] == 'B':
                        gamepad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                        await websocket.send(f"VIBRATE:{100}")
                    elif data[1] == 'X':
                        gamepad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)
                        await websocket.send(f"VIBRATE:{100}")
                    elif data[1] == 'Y':
                        gamepad.press_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)
                        await websocket.send(f"VIBRATE:{100}")
                elif data[0] == "RELEASE":
                    await websocket.send(message)
                    if data[1] == 'A':
                        gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                    elif data[1] == 'B':
                        gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                    elif data[1] == 'X':
                        gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)
                    elif data[1] == 'Y':
                        gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)
            elif len(data) == 3:
                x = float(data[0])
                y = float(data[1])
                z = float(data[2])
                gamepad.right_joystick_float(x, -y)

            if stop:
                # gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_A)
                # gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_B)
                # gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_X)
                # gamepad.release_button(vg.XUSB_BUTTON.XUSB_GAMEPAD_Y)

                # gamepad.right_joystick_float(0, 0)
                # gamepad.left_joystick_float(0, 0)

                gamepad.reset()

                trigger_x, trigger_y = 0, 0

                await websocket.send(message)

                
            if vibration_large > 0: await websocket.send(f"VIBRATE:{vibration_large}") 
            if vibration_small > 0: await websocket.send(f"VIBRATE:{vibration_small}") 

        except websockets.ConnectionClosedOK:
            print("Connection closed OK")
            stop = False
            break
        except websockets.ConnectionClosedError:
            print("Connection closed ERROR")
            stop = False
            break

        gamepad.update()
        time.sleep(0.005)

async def main():
    gamepad.register_notification(rumble_callback)
    async with websockets.serve(handler, "", 80):
        print("listening...")
        await asyncio.Future()  # set this future to exit the server    

asyncio.run(main())