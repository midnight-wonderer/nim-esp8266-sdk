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
## Quick Start

### 1. Installation

Add the library to your project's `.nimble` file:
```nim
requires "esp8266_sdk"
```

Then install dependencies without building:
```bash
nimble install -d
```

> [!IMPORTANT]
> **Avoid `bin = @["application"]` in your `.nimble` file.**
> Nimble's default builder tries to compile for your host PC (x86/ARM), which will fail for this SDK. Always use `nimble install -d` to just fetch dependencies, then use our `init.nims` to configure the cross-compiler.

### 2. Initialization

Run the setup script in your project root. This will generate a `config.nims` (build settings), `src/sdkconfig.h` (SDK defaults), and `nim.cfg` (IDE support):

```bash
nim e $(nimble path esp8266_sdk)/src/init.nims
```

The generated configuration automatically:
- **Configures Cross-Compilation**: CPU, OS, and toolchain paths.
- **Sets Architecture Flags**: `-mlongcalls`, `-mtext-section-literals`, etc.
- **Links SDK Libraries**: Net80211, PP, PHY, HAL, and Core.
- **Manages Linker Scripts**: Handles the complex ESP8266 memory layout.
- **Handles Configuration**: Uses your `src/sdkconfig.h` or falls back to a library default.
- **Adds Tasks**: Provides `nim flash` and `nim setup` (for IDE support).

### 3. Write and Build

Create your main entry point (e.g., `src/main.nim`):

```nim
import esp8266_sdk

proc app_main*() {.exportc.} =
  echo "Hello from Nim on ESP8266!"
```

Compile and flash to your device:

```bash
# Compile
nim c src/main.nim

# Flash (requires esptool.py, usually handled by the helper)
nim flash
```

---

## Features

The library provides Nim bindings and build automation for:
- **Build System**: Automated toolchain and SDK path detection.
- **RTOS**: FreeRTOS tasks, queues, and semaphores.
- **Networking**: Wi-Fi (Station/AP), LwIP (TCP/IP), and mDNS.
- **Storage**: NVS and Flash storage.
- **Hardware**: Timers and GPIO.

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
