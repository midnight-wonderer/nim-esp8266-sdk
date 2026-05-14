#include "esp_event.h"
#include "esp_timer.h"
#include "fix_mdns.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "tcpip_adapter.h"
#include <pthread.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

// FreeRTOS dummies
void vApplicationTickHook(void) {}
void vApplicationIdleHook(void) {}
void vApplicationStackOverflowHook(void *xTask, char *pcTaskName) {}
void vApplicationMallocFailedHook(void) {}

// SDK dummies
void esp_reconfigure_debug_uart(int uart_num) {}

// LwIP / Networking stubs

// mDNS stubs
void mDNS_PlatformLocalIPArray(const char *const mDNSName, void *const IPArray,
                               int const ArraySize) {}
void mDNS_PlatformSourceAddrForDest(void *const DestAddr,
                                    void *const SourceAddr) {}

void esp_vfs_lwip_sockets_register(void) {}

void *_sbrk_r(struct _reent *r, ptrdiff_t incr) { return NULL; }

void esp_sleep_lock(void) {}
void esp_sleep_unlock(void) {}

void __assert_func(const char *file, int line, const char *func,
                   const char *failedexpr) {
  while (1)
    ;
}

void _exit(int status) {
  while (1)
    ;
}

// PThread Mutex Implementation - Handled by SDK pthread component

void esp_supplicant_init(void) {}

void uart_tx_wait_idle(uint8_t uart_no) {}
void abort(void) {
  while (1)
    ;
}

void esp_sleep_start(void) {}
void esp_supplicant_deinit(void) {}
