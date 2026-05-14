#include "fix_mdns.h"
#include <stdio.h>
#include <stdlib.h>
#include <reent.h>
#include <sys/stat.h>
#include "esp_timer.h"
#include "esp_event.h"
#include "tcpip_adapter.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

// FreeRTOS dummies
void vApplicationTickHook(void) {}
void vApplicationIdleHook(void) {}
void vApplicationStackOverflowHook(void* xTask, char* pcTaskName) {}
void vApplicationMallocFailedHook(void) {}

// SDK dummies
void esp_vfs_dev_uart_register(void) {}
void esp_reconfigure_debug_uart(int uart_num) {}

// LwIP / Networking stubs
void ethernetif_input(void* netif, void* pbuf) {}

int igmp_joingroup(void* srcaddr, void* groupaddr) { return 0; }
int igmp_leavegroup(void* srcaddr, void* groupaddr) { return 0; }
int igmp_joingroup_netif(void* netif, void* groupaddr) { return 0; }
int igmp_leavegroup_netif(void* netif, void* groupaddr) { return 0; }

void mld6_joingroup(const ip6_addr_t *srcaddr, const ip6_addr_t *groupaddr) {}
void mld6_leavegroup(const ip6_addr_t *srcaddr, const ip6_addr_t *groupaddr) {}
void mld6_joingroup_netif(struct netif *netif, const ip6_addr_t *groupaddr) {}
void mld6_leavegroup_netif(struct netif *netif, const ip6_addr_t *groupaddr) {}


// mDNS stubs
void mDNS_PlatformLocalIPArray(const char * const mDNSName, void * const IPArray, int const ArraySize) {}
void mDNS_PlatformSourceAddrForDest(void * const DestAddr, void * const SourceAddr) {}

const ip_addr_t ip6_addr_any = { .u_addr = { .ip6 = { { 0, 0, 0, 0 } } }, .type = 6 };

uint16_t inet_chksum(const void *dataptr, uint16_t len) { return 0; }
uint16_t ip_chksum_pseudo(void *p, void *src, void *dest, uint8_t proto, uint16_t proto_len) { return 0; }
uint16_t ip6_chksum_pseudo(void *p, void *src, void *dest, uint8_t proto, uint16_t proto_len) { return 0; }

// Timer and Event stubs
esp_err_t esp_timer_create(const esp_timer_create_args_t* create_args, esp_timer_handle_t* out_handle) { return 0; }
esp_err_t esp_timer_start_periodic(esp_timer_handle_t timer, uint64_t period) { return 0; }
esp_err_t esp_timer_stop(esp_timer_handle_t timer) { return 0; }
esp_err_t esp_timer_delete(esp_timer_handle_t timer) { return 0; }

esp_err_t esp_event_handler_register(esp_event_base_t event_base, int32_t event_id, esp_event_handler_t event_handler, void* event_handler_arg) { return 0; }
esp_err_t esp_event_handler_unregister(esp_event_base_t event_base, int32_t event_id, esp_event_handler_t event_handler) { return 0; }

// System stubs for linker
int pthread_setcancelstate(int state, int *oldstate) { return 0; }
void esp_vfs_lwip_sockets_register(void) {}
int _fstat_r(struct _reent *r, int fd, struct stat *st) { return 0; }
struct _reent* __getreent(void) { return _GLOBAL_REENT; }

_ssize_t _write_r(struct _reent *r, int fd, const void *buf, size_t cnt) { return 0; }
_ssize_t _read_r(struct _reent *r, int fd, void *buf, size_t cnt) { return 0; }
long _lseek_r(struct _reent *r, int fd, long off, int whence) { return 0; }
int _close_r(struct _reent *r, int fd) { return 0; }
void* _sbrk_r(struct _reent *r, ptrdiff_t incr) { return NULL; }

void igmp_init(void) {}
void dns_init(void) {}
void dns_tmr(void) {}
void nd6_tmr(void) {}
void ip6_reass_tmr(void) {}
void mld6_tmr(void) {}
void nd6_find_route(void) {}
void ip6_frag(void) {}
void nd6_get_destination_mtu(void) {}
void icmp_time_exceeded(void) {}
void etharp_tmr(void) {}
void dhcp_coarse_tmr(void) {}
void dhcp_fine_tmr(void) {}
void dhcps_coarse_tmr(void) {}
void igmp_tmr(void) {}
void chip_boot(void) {}
void esp_newlib_init(void) {}
void sha1_vector(void) {}
void esp_reset_reason_early(void) {}
void esp_reset_reason_init(void) {}
void esp_pthread_init(void) {}
int64_t esp_timer_get_time(void) { return 0; }
void esp_sleep_lock(void) {}
void esp_sleep_unlock(void) {}
void Cache_Read_Enable_New(void) {}
void* ip_data;

void __assert_func(const char *file, int line, const char *func, const char *failedexpr) {
    while(1);
}

void _exit(int status) { while(1); }

// PThread stubs using FreeRTOS TLS
int pthread_setspecific(uint32_t key, const void *value) {
    vTaskSetThreadLocalStoragePointer(NULL, (int)key, (void*)value);
    return 0;
}
void* pthread_getspecific(uint32_t key) {
    return pvTaskGetThreadLocalStoragePointer(NULL, (int)key);
}
int pthread_key_create(uint32_t *key, void (*destructor)(void*)) {
    static uint32_t next_key = 0;
    *key = next_key++;
    return 0;
}

// NVS is now implemented in Nim (nvs.nim)

void pp_soft_wdt_stop(void) {}
void pp_soft_wdt_restart(void) {}

void esp_supplicant_init(void) {}
esp_err_t tcpip_adapter_set_default_wifi_handlers(void) { return 0; }
void uart_tx_wait_idle(uint8_t uart_no) {}
void abort(void) { while(1); }

uint8_t esp_crc8(const uint8_t* data, size_t len) { return 0; }
void panicHandler(void* frame) { while(1); }
void esp_task_wdt_reset(void) {}
void esp_sleep_start(void) {}
void esp_supplicant_deinit(void) {}
