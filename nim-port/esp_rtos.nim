import os
import nvs
import timer

const sdkBase = "/storage/projects/ESP8266_RTOS_SDK"
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
{.passC: "-I" & sdkBase / "components/wpa_supplicant/include/esp_supplicant".}
{.passC: "-I" & sdkBase / "components/wpa_supplicant/src/esp_supplicant".}
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
{.passC: "-I" & sdkBase / "components/mdns/include".}
{.passC: "-I" & sdkBase / "components/mdns/private_include".}
{.passC: "-I" & sdkBase / "components/pthread/include".}
{.passC: "-I" & sdkBase / "components/pthread".}
{.passC: "-I" & sdkBase / "components/esp_ringbuf/include".}
{.passC: "-I" & sdkBase / "components/esp_ringbuf/include/freertos".}

# Xtensa specific flags
{.passC: "-mlongcalls -mtext-section-literals".}
{.passC: "-DICACHE_FLASH".}
{.passC: "-fstrict-volatile-bitfields".}

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
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/sha1-pbkdf2.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/aes-omac1.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/sha1.c".}
{.compile: sdkBase / "components/wpa_supplicant/src/crypto/sha1-internal.c".}
{.compile: sdkBase / "components/wpa_supplicant/port/os_xtensa.c".}
{.compile: "stubs.c".}
{.compile: sdkBase / "components/esp8266/source/chip_boot.c".}
{.compile: sdkBase / "components/esp8266/source/backtrace.c".}
{.compile: sdkBase / "components/esp8266/source/reset_reason.c".}
{.compile: sdkBase / "components/esp8266/driver/uart.c".}
{.compile: sdkBase / "components/newlib/src/reent_init.c".}
{.compile: sdkBase / "components/vfs/vfs.c".}
{.compile: sdkBase / "components/vfs/vfs_uart.c".}
{.compile: sdkBase / "components/pthread/pthread.c".}
{.compile: sdkBase / "components/pthread/pthread_local_storage.c".}
{.compile: sdkBase / "components/pthread/pthread_cond_var.c".}
{.compile: sdkBase / "components/freertos/port/esp8266/panic.c".}
{.compile: sdkBase / "components/esp_ringbuf/ringbuf.c".}
{.compile: sdkBase / "components/esp8266/source/esp_wifi.c".}
{.compile: sdkBase / "components/esp8266/source/esp_wifi_os_adapter.c".}
{.compile: sdkBase / "components/esp8266/source/ets_printf.c".}
{.compile: sdkBase / "components/esp8266/source/system_api.c".}
{.compile: sdkBase / "components/esp8266/source/startup.c".}
{.compile: sdkBase / "components/esp8266/source/task_wdt.c".}
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

# LwIP (minimal set for mDNS + TCP server)
{.compile: sdkBase / "components/lwip/lwip/src/core/tcp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/tcp_in.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/tcp_out.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/ip4.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/ip4_addr.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/udp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/pbuf.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/netif.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/timeouts.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/init.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/mem.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ip.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/ip6.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/sockets.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/tcpip.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/ip4_frag.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/def.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/raw.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/memp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/api_lib.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/api_msg.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/netbuf.c".}
{.compile: sdkBase / "components/lwip/lwip/src/api/err.c".}
{.compile: "mdns.c".}
{.compile: "mdns_networking.c".}
{.compile: sdkBase / "components/esp8266/source/crc.c".}
{.compile: sdkBase / "components/spi_flash/src/spi_flash.c".}
{.compile: sdkBase / "components/spi_flash/src/spi_flash_raw.c".}
{.compile: sdkBase / "components/esp_event/default_event_loop.c".}
{.compile: sdkBase / "components/tcpip_adapter/event_handlers.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/icmp6.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/ip6_frag.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/ip6_addr.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/nd6.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/mld6.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv6/ethip6.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/etharp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/igmp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/dhcp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/ipv4/icmp.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/dns.c".}
{.compile: sdkBase / "components/lwip/lwip/src/core/inet_chksum.c".}
{.compile: sdkBase / "components/lwip/apps/dhcpserver/dhcpserver.c".}
{.compile: sdkBase / "components/lwip/lwip/src/netif/ethernet.c".}
{.compile: sdkBase / "components/lwip/port/esp8266/netif/wlanif.c".}
{.compile: sdkBase / "components/lwip/port/esp8266/freertos/sys_arch.c".}

type
  esp_err_t* = int32
  wifi_mode_t* = enum
    WIFI_MODE_NULL = 0, WIFI_MODE_STA, WIFI_MODE_AP, WIFI_MODE_APSTA

const
  WIFI_IF_STA* = 0
  WIFI_IF_AP* = 1

type
  wifi_sta_config_t* {.importc: "wifi_sta_config_t", header: "esp_wifi.h".} = object
    ssid*: array[32, byte]
    password*: array[64, byte]

  wifi_init_config_t* {.importc: "wifi_init_config_t", header: "esp_wifi.h".} = object
    rx_buf_num*: uint8
    rx_pkt_num*: uint8
    tx_buf_num*: uint8
    nvs_enable*: uint8
    magic*: uint32

  wifi_config_t* {.importc: "wifi_config_t", header: "esp_wifi.h", union.} = object
    sta*: wifi_sta_config_t

proc esp_wifi_init*(config: ptr wifi_init_config_t): esp_err_t {.importc: "esp_wifi_init", header: "esp_wifi.h".}
proc esp_wifi_set_mode*(mode: wifi_mode_t): esp_err_t {.importc: "esp_wifi_set_mode", header: "esp_wifi.h".}
proc esp_wifi_set_config*(interface_id: int, config: ptr wifi_config_t): esp_err_t {.importc: "esp_wifi_set_config", header: "esp_wifi.h".}
proc esp_wifi_start*(): esp_err_t {.importc: "esp_wifi_start", header: "esp_wifi.h".}
proc esp_wifi_connect*(): esp_err_t {.importc: "esp_wifi_connect", header: "esp_wifi.h".}

proc tcpip_adapter_init*() {.importc: "tcpip_adapter_init", header: "tcpip_adapter.h".}
proc esp_event_loop_create_default*(): esp_err_t {.importc: "esp_event_loop_create_default", header: "esp_event.h".}

proc mdns_init*(): esp_err_t {.importc: "mdns_init", header: "mdns.h".}
proc mdns_hostname_set*(hostname: cstring): esp_err_t {.importc: "mdns_hostname_set", header: "mdns.h".}
proc mdns_instance_name_set*(instance_name: cstring): esp_err_t {.importc: "mdns_instance_name_set", header: "mdns.h".}
proc mdns_service_add*(instance_name: cstring, service_type: cstring, proto: cstring, port: uint16, txt: pointer, num_items: int): esp_err_t {.importc: "mdns_service_add", header: "mdns.h".}

# LwIP Socket API
type
  Socket* = int32
  InAddr* {.importc: "struct in_addr", header: "lwip/sockets.h".} = object
    s_addr*: uint32

  SockAddrIn* {.importc: "struct sockaddr_in", header: "lwip/sockets.h".} = object
    sin_len*: uint8
    sin_family*: uint8
    sin_port*: uint16
    sin_addr*: InAddr
    sin_zero*: array[8, char]

const
  AF_INET* = 2
  SOCK_STREAM* = 1
  IPPROTO_IP* = 0
  INADDR_ANY* = 0

proc socket*(domain: int32, stype: int32, protocol: int32): Socket {.importc: "lwip_socket", header: "lwip/sockets.h".}
proc `bind`*(s: Socket, name: ptr SockAddrIn, namelen: uint32): int32 {.importc: "lwip_bind", header: "lwip/sockets.h".}
proc listen*(s: Socket, backlog: int32): int32 {.importc: "lwip_listen", header: "lwip/sockets.h".}
proc accept*(s: Socket, address: pointer, addrlen: pointer): Socket {.importc: "lwip_accept", header: "lwip/sockets.h".}
proc recv*(s: Socket, mem: pointer, len: int, flags: int32): int {.importc: "lwip_recv", header: "lwip/sockets.h".}
proc send*(s: Socket, data: pointer, len: int, flags: int32): int {.importc: "lwip_send", header: "lwip/sockets.h".}
proc close*(s: Socket): int32 {.importc: "lwip_close", header: "lwip/sockets.h".}
proc htons*(x: uint16): uint16 {.importc: "lwip_htons", header: "lwip/def.h".}

template WIFI_INIT_CONFIG_DEFAULT*(): wifi_init_config_t =
  var config: wifi_init_config_t
  config

proc vTaskDelay*(ticks: uint32) {.importc: "vTaskDelay", header: "freertos/FreeRTOS.h".}
