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
- **Nim**: Version 2.

## Configuration

To simplify your project setup, the library provides a centralized configuration helper. Create a `config.nims` in your project root with the following content:

```nim
import os, strutils
const sdkPath = gorge("nimble path esp8266_sdk").strip()
if sdkPath != "":
  include sdkPath / "src/config_helper.nims"
```

This helper automatically:
1. Configures the cross-compiler and architecture flags.
2. Sets up the linker scripts and static libraries.
3. Provides a `flash` task (`nim flash`).
4. Provides a `setup` task (`nim setup`) to generate `nim.cfg` for IDE support.
5. Handles `sdkconfig.h` (uses your project's `src/sdkconfig.h` if present, otherwise falls back to a library default).

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

Since this library vendors the original SDK and its components as plain files (submodules removed for simplicity), you can use the provided `justfile` to update to the latest stable release (`release/v3.4`):

```bash
just update-all      # Update SDK and all sub-components to stable release
```

This command clones the SDK recursively to ensure all components (LwIP, mbedTLS, etc.) are at the exact versions verified by Espressif for the stable branch.

Alternatively, you can manually check the following upstream repositories:

- **Main SDK**: [espressif/ESP8266_RTOS_SDK](https://github.com/espressif/ESP8266_RTOS_SDK)
- **LwIP**: [espressif/esp-lwip](https://github.com/espressif/esp-lwip)
- **mbedTLS**: [espressif/mbedtls](https://github.com/espressif/mbedtls)
- **cJSON**: [DaveGamble/cJSON](https://github.com/DaveGamble/cJSON)
- **MQTT**: [espressif/esp-mqtt](https://github.com/espressif/esp-mqtt)
- **CoAP**: [obgm/libcoap](https://github.com/obgm/libcoap)

## License

This project is licensed under Apache-2.0, same as the ESP8266_RTOS_SDK.
