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

void esp_sleep_lock(void) {}
void esp_sleep_unlock(void) {}

void __assert_func(const char *file, int line, const char *func,
                   const char *failedexpr) {
  while (1)
    ;
}

void uart_tx_wait_idle(uint8_t uart_no) {}

void esp_sleep_start(void) {}

// Supplicant/WPA3 Stubs (Safe to stub if not using SAE or SoftAP)
void esp_wpa3_free_sae_data(void) {}
void hostapd_get_psk(void) {}
void wpa_receive(void) {}
void esp_wifi_register_wpa3_cb(void *cb) {}
void wpa_ap_join(void) {}
void wpa_ap_remove(void) {}
void hostap_init(void) {}
void hostap_deinit(void) {}
