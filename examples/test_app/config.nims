# config.nims
import os

# Set up the cross-compiler
const sdkBase = projectDir() / "../../"
const toolchainPath = getHomeDir() / "esp/xtensa-lx106-elf/bin"
putEnv("PATH", toolchainPath & PathSep & getEnv("PATH"))

# Add library src to path
switch("path", sdkBase / "src")

# Nim compiler settings for ESP8266
switch("cpu", "riscv32") # Nim doesn't have a specific 'xtensa' CPU type, but we can override it
switch("os", "any")
switch("threads", "off")
switch("mm", "arc")
switch("define", "noSignalHandler")
switch("define", "dynlibOverrideAll")
switch("define", "useMalloc")
switch("gcc.exe", "xtensa-lx106-elf-gcc")
switch("gcc.linkerexe", "xtensa-lx106-elf-gcc")
switch("gcc.path", toolchainPath)
switch("gcc.options.linker", "")

# Architecture specific flags
switch("passC", "-mlongcalls")
switch("passC", "-mtext-section-literals")
switch("passC", "-DICACHE_FLASH")
switch("passC", "-fstrict-volatile-bitfields")
switch("passC", "-ffunction-sections")
switch("passC", "-fdata-sections")
switch("passC", "-DCONFIG_IEEE80211W")
switch("passC", "-DLWIP_IPV6=1")
switch("passC", "-DESP_SUPPLICANT")
switch("passC", "-DCONFIG_WPA3_SAE")
switch("passC", "-D__bswap_16=__builtin_bswap16")
switch("passC", "-D__bswap_32=__builtin_bswap32")
switch("passC", "-DCONFIG_ESP8266_TIME_SYSCALL_USE_FRC1")
switch("passC", "-include sdkconfig.h")

# Linker flags
switch("passL", "-Wl,--gc-sections")
switch("passL", "-nostdlib")

const sdkLdPath = sdkBase / "vendor/components/esp8266/ld"
switch("passL", "-L" & sdkLdPath)
switch("passL", "-T" & sdkLdPath / "esp8266.rom.ld")
switch("passL", "-T" & sdkLdPath / "esp8266.peripherals.ld")
switch("passL", "-T" & sdkBase / "src/esp8266_nim.ld")

# Libraries
switch("passL", "-L/home/san/esp/xtensa-lx106-elf/xtensa-lx106-elf/lib")
switch("passL", "-L/home/san/esp/xtensa-lx106-elf/lib/gcc/xtensa-lx106-elf/8.4.0")
switch("passL", "-lc")
switch("passL", "-lm")
switch("passL", "-lgcc")
switch("passL", "-L" & sdkBase / "vendor/components/esp8266/lib")
switch("passL", "-lnet80211 -lpp -lphy -lhal -lcore -lrtc -lclk -lsmartconfig")

task flash, "Convert to bin and flash to ESP8266":
  let esptool = sdkBase / "vendor/components/esptool_py/esptool/esptool.py"
  exec "python3 " & esptool & " --chip esp8266 elf2image --flash_mode dio --flash_freq 40m --flash_size 4MB main"
  exec "python3 " & esptool & " --chip esp8266 --port /dev/ttyUSB0 --baud 115200 write_flash 0x0 main-0x00000.bin 0x10000 main-0x10000.bin"
