import strutils
import nvs
import timer

# Path manipulation helpers that work at compile-time even with --os:any
func parentDir(path: string): string =
  var i = path.len - 1
  while i >= 0:
    if path[i] in {'/', '\\'}: return path[0 ..< i]
    dec i
  return "."

template `/`(a, b: string): string = a & "/" & b

const thisDir = parentDir(currentSourcePath())
const sdkBase = static:
  if staticExec("test -d " & thisDir & "/vendor && echo true").strip == "true":
    thisDir
  else:
    parentDir(thisDir)

const portBase = thisDir

# Compiler Flags
{.passC: "-I" & portBase.}
{.passC: "-I" & sdkBase / "vendor/components/esp8266/include".}
{.passC: "-I" & sdkBase / "vendor/components/bootloader_support/include".}
{.passC: "-I" & sdkBase / "vendor/components/freertos/include".}
{.passC: "-I" & sdkBase / "vendor/components/freertos/include/freertos".}
{.passC: "-I" & sdkBase / "vendor/components/freertos/include/freertos/private".}
{.passC: "-I" & sdkBase / "vendor/components/freertos/port/esp8266/include".}
{.passC: "-I" & sdkBase / "vendor/components/freertos/port/esp8266/include/freertos".}
{.passC: "-I" & sdkBase / "vendor/components/vfs/include".}
{.passC: "-I" & sdkBase / "vendor/components/newlib/platform_include".}
{.passC: "-I" & sdkBase / "vendor/components/wpa_supplicant/include".}
{.passC: "-I" & sdkBase / "vendor/components/wpa_supplicant/src".}
{.passC: "-I" & sdkBase / "vendor/components/wpa_supplicant/src/crypto".}
{.passC: "-I" & sdkBase / "vendor/components/wpa_supplicant/port/include".}
{.passC: "-I" & sdkBase / "vendor/components/wpa_supplicant/include/esp_supplicant".}
{.passC: "-I" & sdkBase / "vendor/components/wpa_supplicant/src/esp_supplicant".}
{.passC: "-I" & sdkBase / "vendor/components/lwip/include/apps".}
{.passC: "-I" & sdkBase / "vendor/components/lwip/include/apps/sntp".}
{.passC: "-I" & sdkBase / "vendor/components/lwip/lwip/src/include".}
{.passC: "-I" & sdkBase / "vendor/components/lwip/port/esp8266/include".}
{.passC: "-I" & sdkBase / "vendor/components/tcpip_adapter/include".}
{.passC: "-I" & sdkBase / "vendor/components/esp_common/include".}
{.passC: "-I" & sdkBase / "vendor/components/log/include".}
{.passC: "-I" & sdkBase / "vendor/components/heap/include".}
{.passC: "-I" & sdkBase / "vendor/components/heap/port/esp8266/include".}
{.passC: "-I" & sdkBase / "vendor/components/esp_event/include".}
{.passC: "-I" & sdkBase / "vendor/components/esp_event/private_include".}
{.passC: "-I" & sdkBase / "vendor/components/nvs_flash/include".}
{.passC: "-I" & sdkBase / "vendor/components/spi_flash/include".}
{.passC: "-I" & sdkBase / "vendor/components/mdns/include".}
{.passC: "-I" & sdkBase / "vendor/components/mdns/private_include".}
{.passC: "-I" & sdkBase / "vendor/components/pthread/include".}
{.passC: "-I" & sdkBase / "vendor/components/pthread".}
{.passC: "-I" & sdkBase / "vendor/components/esp_ringbuf/include".}
{.passC: "-I" & sdkBase / "vendor/components/esp_ringbuf/include/freertos".}

# Xtensa specific flags
{.passC: "-mlongcalls -mtext-section-literals".}
{.passC: "-DICACHE_FLASH".}
{.passC: "-fstrict-volatile-bitfields".}

# Linker Libs
{.passL: "-L" & sdkBase / "vendor/components/esp8266/lib".}
{.passL: "-lnet80211 -lpp -lphy -lhal -lcore -lrtc -lclk -lsmartconfig".}

# Core C Files (to be compiled by Nim)
{.compile: sdkBase / "vendor/components/esp8266/source/hw_random.c".}
{.compile: sdkBase / "vendor/components/esp8266/driver/gpio.c".}
{.compile: sdkBase / "vendor/components/esp8266/driver/adc.c".}
{.compile: sdkBase / "vendor/components/esp8266/driver/i2c.c".}
{.compile: sdkBase / "vendor/components/esp8266/driver/spi.c".}
{.compile: sdkBase / "vendor/components/esp8266/driver/pwm.c".}
{.compile: sdkBase / "vendor/components/esp_event/esp_event.c".}
{.compile: sdkBase / "vendor/components/esp_event/event_send.c".}
{.compile: "stubs.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/chip_boot.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/backtrace.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/reset_reason.c".}
{.compile: sdkBase / "vendor/components/esp8266/driver/uart.c".}
{.compile: sdkBase / "vendor/components/newlib/src/reent_init.c".}
{.compile: sdkBase / "vendor/components/vfs/vfs.c".}
{.compile: sdkBase / "vendor/components/vfs/vfs_uart.c".}
{.compile: sdkBase / "vendor/components/pthread/pthread.c".}
{.compile: sdkBase / "vendor/components/pthread/pthread_local_storage.c".}
{.compile: sdkBase / "vendor/components/pthread/pthread_cond_var.c".}
{.compile: sdkBase / "vendor/components/freertos/port/esp8266/panic.c".}
{.compile: sdkBase / "vendor/components/esp_ringbuf/ringbuf.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/esp_wifi.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/esp_wifi_os_adapter.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/ets_printf.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/system_api.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/startup.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/task_wdt.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/phy_init.c".}
{.compile: sdkBase / "vendor/components/tcpip_adapter/tcpip_adapter_lwip.c".}
{.compile: sdkBase / "vendor/components/log/log.c".}
{.compile: sdkBase / "vendor/components/heap/src/esp_heap_caps.c".}
{.compile: sdkBase / "vendor/components/heap/port/esp8266/esp_heap_init.c".}
{.compile: sdkBase / "vendor/components/freertos/freertos/tasks.c".}
{.compile: sdkBase / "vendor/components/freertos/freertos/list.c".}
{.compile: sdkBase / "vendor/components/freertos/freertos/queue.c".}
{.compile: sdkBase / "vendor/components/freertos/freertos/timers.c".}
{.compile: sdkBase / "vendor/components/freertos/freertos/event_groups.c".}
{.compile: sdkBase / "vendor/components/freertos/port/esp8266/port.c".}
{.compile: sdkBase / "vendor/components/freertos/port/esp8266/os_cpu_a.S".}
{.compile: sdkBase / "vendor/components/freertos/port/esp8266/xtensa_context.S".}
{.compile: sdkBase / "vendor/components/freertos/port/esp8266/xtensa_vectors.S".}

# LwIP
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/tcp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/tcp_in.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/tcp_out.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/ip4.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/ip4_addr.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/udp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/pbuf.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/netif.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/timeouts.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/init.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/mem.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ip.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/ip6.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/api/sockets.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/api/tcpip.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/ip4_frag.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/def.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/raw.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/memp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/api/api_lib.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/api/api_msg.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/api/netbuf.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/api/err.c".}
{.compile: "mdns.c".}
{.compile: "mdns_networking.c".}
{.compile: sdkBase / "vendor/components/esp8266/source/crc.c".}
{.compile: sdkBase / "vendor/components/spi_flash/src/spi_flash.c".}
{.compile: sdkBase / "vendor/components/spi_flash/src/spi_flash_raw.c".}
{.compile: sdkBase / "vendor/components/esp_event/default_event_loop.c".}
{.compile: sdkBase / "vendor/components/tcpip_adapter/event_handlers.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/icmp6.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/ip6_frag.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/ip6_addr.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/nd6.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/mld6.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv6/ethip6.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/etharp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/igmp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/dhcp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/ipv4/icmp.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/dns.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/core/inet_chksum.c".}
{.compile: sdkBase / "vendor/components/lwip/apps/dhcpserver/dhcpserver.c".}
{.compile: sdkBase / "vendor/components/lwip/lwip/src/netif/ethernet.c".}
{.compile: sdkBase / "vendor/components/lwip/port/esp8266/netif/wlanif.c".}
{.compile: sdkBase / "vendor/components/lwip/port/esp8266/freertos/sys_arch.c".}
{.compile: sdkBase / "vendor/components/lwip/port/esp8266/vfs_lwip.c".}
{.compile: sdkBase / "vendor/components/newlib/src/syscall.c".}
{.compile: sdkBase / "vendor/components/newlib/src/time.c".}

# WPA Supplicant
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/rsn_supp/wpa.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/rsn_supp/wpa_ie.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/rsn_supp/pmksa_cache.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/common/wpa_common.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/esp_supplicant/esp_wpas_glue.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/esp_supplicant/esp_wpa_main.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/utils/common.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/utils/wpa_debug.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/utils/wpabuf.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/md5.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/md5-internal.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-unwrap.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-wrap.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-ccm.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/ccmp.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-internal.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-internal-enc.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-internal-dec.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/aes-omac1.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/rc4.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/sha256.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/sha256-prf.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/sha256-internal.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/sha1.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/sha1-internal.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/sha1-pbkdf2.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/src/crypto/crypto_ops.c".}
{.compile: sdkBase / "vendor/components/wpa_supplicant/port/os_xtensa.c".}

type
  esp_err_t* = int32
  wifi_mode_t* = enum
    WIFI_MODE_NULL = 0, WIFI_MODE_STA, WIFI_MODE_AP, WIFI_MODE_APSTA

const
  WIFI_IF_STA* = 0
  WIFI_IF_AP* = 1

type
  wifi_sta_config_t* {.importc: "wifi_sta_config_t",
      header: "esp_wifi.h".} = object
    ssid*: array[32, byte]
    password*: array[64, byte]

  wifi_init_config_t* {.importc: "wifi_init_config_t",
      header: "esp_wifi.h".} = object
    rx_buf_num*: uint8
    rx_pkt_num*: uint8
    tx_buf_num*: uint8
    nvs_enable*: uint8
    magic*: uint32

  wifi_config_t* {.importc: "wifi_config_t", header: "esp_wifi.h",
      union.} = object
    sta*: wifi_sta_config_t

proc esp_wifi_init*(config: ptr wifi_init_config_t): esp_err_t {.importc: "esp_wifi_init",
    header: "esp_wifi.h".}
proc esp_wifi_set_mode*(mode: wifi_mode_t): esp_err_t {.importc: "esp_wifi_set_mode",
    header: "esp_wifi.h".}
proc esp_wifi_set_config*(interface_id: int,
    config: ptr wifi_config_t): esp_err_t {.importc: "esp_wifi_set_config",
    header: "esp_wifi.h".}
proc esp_wifi_start*(): esp_err_t {.importc: "esp_wifi_start",
    header: "esp_wifi.h".}
proc esp_wifi_connect*(): esp_err_t {.importc: "esp_wifi_connect",
    header: "esp_wifi.h".}

proc tcpip_adapter_init*() {.importc: "tcpip_adapter_init",
    header: "tcpip_adapter.h".}
proc esp_event_loop_create_default*(): esp_err_t {.importc: "esp_event_loop_create_default",
    header: "esp_event.h".}

proc mdns_init*(): esp_err_t {.importc: "mdns_init", header: "mdns.h".}
proc mdns_hostname_set*(hostname: cstring): esp_err_t {.importc: "mdns_hostname_set",
    header: "mdns.h".}
proc mdns_instance_name_set*(instance_name: cstring): esp_err_t {.importc: "mdns_instance_name_set",
    header: "mdns.h".}
proc mdns_service_add*(instance_name: cstring, service_type: cstring,
    proto: cstring, port: uint16, txt: pointer,
    num_items: int): esp_err_t {.importc: "mdns_service_add", header: "mdns.h".}

# LwIP Socket API
type
  Socket* = int32
  InAddr* {.importc: "struct in_addr", header: "lwip/sockets.h".} = object
    s_addr*: uint32

  SockAddrIn* {.importc: "struct sockaddr_in",
      header: "lwip/sockets.h".} = object
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

proc socket*(domain: int32, stype: int32,
    protocol: int32): Socket {.importc: "lwip_socket",
    header: "lwip/sockets.h".}
proc `bind`*(s: Socket, name: ptr SockAddrIn,
    namelen: uint32): int32 {.importc: "lwip_bind", header: "lwip/sockets.h".}
proc listen*(s: Socket, backlog: int32): int32 {.importc: "lwip_listen",
    header: "lwip/sockets.h".}
proc accept*(s: Socket, address: pointer,
    addrlen: pointer): Socket {.importc: "lwip_accept",
    header: "lwip/sockets.h".}
proc recv*(s: Socket, mem: pointer, len: int,
    flags: int32): int {.importc: "lwip_recv", header: "lwip/sockets.h".}
proc send*(s: Socket, data: pointer, len: int,
    flags: int32): int {.importc: "lwip_send", header: "lwip/sockets.h".}
proc close*(s: Socket): int32 {.importc: "lwip_close",
    header: "lwip/sockets.h".}
proc htons*(x: uint16): uint16 {.importc: "lwip_htons", header: "lwip/def.h".}

template WIFI_INIT_CONFIG_DEFAULT*(): wifi_init_config_t =
  var config: wifi_init_config_t
  config

proc vTaskDelay*(ticks: uint32) {.importc: "vTaskDelay",
    header: "freertos/FreeRTOS.h".}
