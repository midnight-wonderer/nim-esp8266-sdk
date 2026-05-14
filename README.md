# esp8266_sdk

A Nim wrapper for the [ESP8266_RTOS_SDK](https://github.com/espressif/ESP8266_RTOS_SDK).

This library packages the entire ESP8266_RTOS_SDK and provides Nim bindings for core functionality, including:
- FreeRTOS tasks and primitives
- Wi-Fi (Station and AP modes)
- TCP/IP (LwIP)
- mDNS
- NVS and Flash storage
- Hardware Timers

## Prerequisites

- **Xtensa Toolchain**: You must have `xtensa-lx106-elf-gcc` in your PATH.
- **Nim**: Version 1.6.0 or higher.

## Usage

Add this to your `.nimble` file:
```nim
requires "esp8266_sdk"
```

Then in your Nim code:
```nim
import esp8266_sdk

proc app_main*() {.exportc.} =
  echo "Hello from Nim on ESP8266!"
```

## Structure

- `src/`: Nim source files and C stubs.
- `vendor/`: The original ESP8266_RTOS_SDK.
- `examples/`: Example applications.

## Building the Example

```bash
cd examples/test_app
nim c main.nim
# To flash:
nim flash
```

## Maintenance

Since this library vendors the original SDK and its components as plain files (submodules removed for simplicity), you can check the following upstream repositories for updates:

- **Main SDK**: [espressif/ESP8266_RTOS_SDK](https://github.com/espressif/ESP8266_RTOS_SDK)
- **LwIP**: [espressif/esp-lwip](https://github.com/espressif/esp-lwip)
- **mbedTLS**: [espressif/mbedtls](https://github.com/espressif/mbedtls)
- **cJSON**: [DaveGamble/cJSON](https://github.com/DaveGamble/cJSON)
- **MQTT**: [espressif/esp-mqtt](https://github.com/espressif/esp-mqtt)
- **CoAP**: [obgm/libcoap](https://github.com/obgm/libcoap)

## License

This project is licensed under Apache-2.0, same as the ESP8266_RTOS_SDK.
