# esp_rtos.nim
import os

const sdkBase = currentSourcePath().parentDir().parentDir()
const portBase = currentSourcePath().parentDir()

# Compiler Flags
{.passC: "-I" & portBase.}
{.passC: "-I" & sdkBase / "components/esp8266/include".}
{.passC: "-I" & sdkBase / "components/bootloader_support/include".}
{.passC: "-I" & sdkBase / "components/freertos/include".}
{.passC: "-I" & sdkBase / "components/freertos/include/freertos".}
{.passC: "-I" & sdkBase / "components/freertos/include/freertos/private".}
{.passC: "-I" & sdkBase / "components/freertos/port/esp8266/include".}
{.passC: "-I" & sdkBase / "components/freertos/port/esp8266/include/freertos".}
{.passC: "-I" & sdkBase / "components/vfs/include".}
{.passC: "-I" & sdkBase / "components/newlib/platform_include".}
{.passC: "-I" & sdkBase / "components/wpa_supplicant/include".}
{.passC: "-I" & sdkBase / "components/wpa_supplicant/src".}
{.passC: "-I" & sdkBase / "components/wpa_supplicant/src/crypto".}
{.passC: "-I" & sdkBase / "components/wpa_supplicant/port/include".}
{.passC: "-I" & sdkBase / "components/lwip/include/apps".}
{.passC: "-I" & sdkBase / "components/lwip/include/apps/sntp".}
{.passC: "-I" & sdkBase / "components/lwip/lwip/src/include".}
{.passC: "-I" & sdkBase / "components/lwip/port/esp8266/include".}
{.passC: "-I" & sdkBase / "components/tcpip_adapter/include".}
{.passC: "-I" & sdkBase / "components/esp_common/include".}
{.passC: "-I" & sdkBase / "components/log/include".}
{.passC: "-I" & sdkBase / "components/heap/include".}
{.passC: "-I" & sdkBase / "components/heap/port/esp8266/include".}
{.passC: "-I" & sdkBase / "components/esp_event/include".}
{.passC: "-I" & sdkBase / "components/esp_event/private_include".}
{.passC: "-I" & sdkBase / "components/nvs_flash/include".}
{.passC: "-I" & sdkBase / "components/spi_flash/include".}

# Linker Libs
{.passL: "-L" & sdkBase / "components/esp8266/lib".}
{.passL: "-lnet80211 -lpp -lphy -lhal -lcore -lrtc -lclk -lsmartconfig".}

# Core C Files (to be compiled by Nim)
{.compile: sdkBase / "components/esp8266/source/hw_random.c".}
{.compile: sdkBase / "components/esp_event/esp_event.c".}
{.compile: sdkBase / "components/esp_event/event_send.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/ccmp.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/aes-ccm.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/aes-internal.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/aes-internal-enc.c".}
{.compile: portBase / "stubs.c".}
{.compile: sdkBase / "components/esp8266/source/esp_wifi.c".}
{.compile: sdkBase / "components/esp8266/source/esp_wifi_os_adapter.c".}
{.compile: sdkBase / "components/esp8266/source/ets_printf.c".}
{.compile: sdkBase / "components/esp8266/source/system_api.c".}
{.compile: sdkBase / "components/esp8266/source/startup.c".}
{.compile: sdkBase / "components/esp8266/source/phy_init.c".}
{.compile: sdkBase / "components/tcpip_adapter/tcpip_adapter_lwip.c".}
{.compile: sdkBase / "components/log/log.c".}
{.compile: sdkBase / "components/heap/src/esp_heap_caps.c".}
{.compile: sdkBase / "components/heap/port/esp8266/esp_heap_init.c".}
{.compile: sdkBase / "components/freertos/freertos/tasks.c".}
{.compile: sdkBase / "components/freertos/freertos/list.c".}
{.compile: sdkBase / "components/freertos/freertos/queue.c".}
{.compile: sdkBase / "components/freertos/freertos/timers.c".}
{.compile: sdkBase / "components/freertos/freertos/event_groups.c".}
{.compile: sdkBase / "components/freertos/port/esp8266/port.c".}
{.compile: sdkBase / "components/freertos/port/esp8266/os_cpu_a.S".}
{.compile: sdkBase / "components/freertos/port/esp8266/xtensa_context.S".}
{.compile: sdkBase / "components/freertos/port/esp8266/xtensa_vectors.S".}

# LwIP (minimal set for TCP server)
{.compile: sdkBase / "components/lwip/lwip/src/core/tcp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/tcp_in.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/tcp_out.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/ip4.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/ip4_addr.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/pbuf.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/netif.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/timeouts.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/sockets.c".}
{.compile: sdkBase / "components/lwip/port/esp8266/freertos/sys_arch.c".}

# For a library, we want to expose types and procs
type
  esp_err_t* = int32
  socklen_t* = uint32

const
  ESP_OK* = 0
  AF_INET* = 2
  SOCK_STREAM* = 1
  IPPROTO_TCP* = 6

type
  in_addr* {.importc: "struct in_addr", header: "lwip/sockets.h".} = object
    s_addr*: uint32

  sockaddr_in* {.importc: "struct sockaddr_in", header: "lwip/sockets.h".} = object
    sin_len*: uint8
    sin_family*: uint8
    sin_port*: uint16
    sin_addr*: in_addr
    sin_zero*: array[8, char]

  sockaddr* {.importc: "struct sockaddr", header: "lwip/sockets.h".} = object

# Wi-Fi
proc esp_wifi_init*(config: pointer): esp_err_t {.importc, header: "esp_wifi.h".}
proc esp_wifi_set_mode*(mode: int32): esp_err_t {.importc, header: "esp_wifi.h".}
proc esp_wifi_start*(): esp_err_t {.importc, header: "esp_wifi.h".}

# Sockets
proc lwip_socket*(domain, socketType, protocol: int32): int32 {.importc, header: "lwip/sockets.h".}
proc lwip_bind*(s: int32, name: ptr sockaddr, namelen: socklen_t): int32 {.importc, header: "lwip/sockets.h".}
proc lwip_listen*(s: int32, backlog: int32): int32 {.importc, header: "lwip/sockets.h".}
proc lwip_accept*(s: int32, address: ptr sockaddr, addrlen: ptr socklen_t): int32 {.importc, header: "lwip/sockets.h".}
proc lwip_read*(s: int32, mem: pointer, len: csize_t): int32 {.importc, header: "lwip/sockets.h".}
proc lwip_write*(s: int32, dataptr: pointer, size: csize_t): int32 {.importc, header: "lwip/sockets.h".}
proc lwip_close*(s: int32): int32 {.importc, header: "lwip/sockets.h".}

# Helper for htons
proc htons*(hostshort: uint16): uint16 =
  return (hostshort shl 8) or (hostshort shr 8)
