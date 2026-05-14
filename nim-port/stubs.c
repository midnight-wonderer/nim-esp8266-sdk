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
void esp_vfs_dev_uart_register(void) {}
void esp_reconfigure_debug_uart(int uart_num) {}

// LwIP / Networking stubs

// mDNS stubs
void mDNS_PlatformLocalIPArray(const char *const mDNSName, void *const IPArray,
                               int const ArraySize) {}
void mDNS_PlatformSourceAddrForDest(void *const DestAddr,
                                    void *const SourceAddr) {}

// System stubs for linker
int pthread_setcancelstate(int state, int *oldstate) { return 0; }
void esp_vfs_lwip_sockets_register(void) {}
int _fstat_r(struct _reent *r, int fd, struct stat *st) { return 0; }
struct _reent *__getreent(void) { return _GLOBAL_REENT; }

_ssize_t _write_r(struct _reent *r, int fd, const void *buf, size_t cnt) {
  return 0;
}
_ssize_t _read_r(struct _reent *r, int fd, void *buf, size_t cnt) { return 0; }
long _lseek_r(struct _reent *r, int fd, long off, int whence) { return 0; }
int _close_r(struct _reent *r, int fd) { return 0; }
void *_sbrk_r(struct _reent *r, ptrdiff_t incr) { return NULL; }

void chip_boot(void) {}
void esp_newlib_init(void) {}
void sha1_vector(void) {}
void esp_reset_reason_early(void) {}
void esp_reset_reason_init(void) {}
void esp_pthread_init(void) {}

void esp_sleep_lock(void) {}
void esp_sleep_unlock(void) {}
void *ip_data;

void __assert_func(const char *file, int line, const char *func,
                   const char *failedexpr) {
  while (1)
    ;
}

void _exit(int status) {
  while (1)
    ;
}

// PThread Mutex Implementation
int pthread_mutex_init(pthread_mutex_t *mutex,
                       const pthread_mutexattr_t *attr) {
  *mutex = (pthread_mutex_t)xSemaphoreCreateMutex();
  return (*mutex == NULL) ? ENOMEM : 0;
}

int pthread_mutex_destroy(pthread_mutex_t *mutex) {
  if (mutex && *mutex) {
    vSemaphoreDelete((SemaphoreHandle_t)*mutex);
    *mutex = NULL;
  }
  return 0;
}

int pthread_mutex_lock(pthread_mutex_t *mutex) {
  if (mutex == NULL)
    return EINVAL;
  if (*mutex == NULL) {
    // Handle static PTHREAD_MUTEX_INITIALIZER
    *mutex = (pthread_mutex_t)xSemaphoreCreateMutex();
  }
  return (xSemaphoreTake((SemaphoreHandle_t)*mutex, portMAX_DELAY) == pdTRUE)
             ? 0
             : EINVAL;
}

int pthread_mutex_unlock(pthread_mutex_t *mutex) {
  if (mutex == NULL || *mutex == NULL)
    return EINVAL;
  return (xSemaphoreGive((SemaphoreHandle_t)*mutex) == pdTRUE) ? 0 : EINVAL;
}

// PThread Once Implementation
int pthread_once(pthread_once_t *once_control, void (*init_routine)(void)) {
  if (once_control == NULL || init_routine == NULL)
    return EINVAL;
  if (once_control->init_executed == 0) {
    init_routine();
    once_control->init_executed = 1;
  }
  return 0;
}

// PThread Thread Identification
pthread_t pthread_self(void) { return (pthread_t)xTaskGetCurrentTaskHandle(); }

int pthread_equal(pthread_t t1, pthread_t t2) { return (t1 == t2); }

// PThread stubs using FreeRTOS TLS
int pthread_setspecific(pthread_key_t key, const void *value) {
  vTaskSetThreadLocalStoragePointer(NULL, (int)key, (void *)value);
  return 0;
}

void *pthread_getspecific(pthread_key_t key) {
  return pvTaskGetThreadLocalStoragePointer(NULL, (int)key);
}

int pthread_key_create(pthread_key_t *key, void (*destructor)(void *)) {
  static uint32_t next_key = 0;
  *key = next_key++;
  return 0;
}

void esp_supplicant_init(void) {}

void uart_tx_wait_idle(uint8_t uart_no) {}
void abort(void) {
  while (1)
    ;
}

void panicHandler(void *frame) {
  while (1)
    ;
}

void esp_sleep_start(void) {}
void esp_supplicant_deinit(void) {}
