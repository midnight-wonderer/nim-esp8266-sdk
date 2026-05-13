#include <stdio.h>
#include <stdlib.h>
#include <reent.h>
#include <sys/stat.h>
#include <sys/types.h>

#define IRAM_ATTR __attribute__((section(".iram1.text")))

void exit(int status) {
    while(1);
}

void abort() {
    while(1);
}

// Newlib reentrancy support
struct _reent * _impure_ptr = NULL;

struct _reent * __getreent() {
    if (!_impure_ptr) {
        static struct _reent early_reent;
        _impure_ptr = &early_reent;
    }
    return _impure_ptr;
}

// Memory allocation syscall
extern char _heap_start;
static char *heap_ptr = &_heap_start;

void * _sbrk_r(struct _reent *r, ptrdiff_t incr) {
    char *prev_heap_ptr = heap_ptr;
    heap_ptr += incr;
    return (void *)prev_heap_ptr;
}

// I/O syscall stubs
int _read_r(struct _reent *r, int fd, void *buf, size_t cnt) { return 0; }
int _write_r(struct _reent *r, int fd, const void *buf, size_t cnt) { return cnt; }
int _close_r(struct _reent *r, int fd) { return 0; }
off_t _lseek_r(struct _reent *r, int fd, off_t pos, int whence) { return 0; }
int _fstat_r(struct _reent *r, int fd, struct stat *st) {
    st->st_mode = S_IFCHR;
    return 0;
}

// Pthread stubs for newlib
int pthread_setcancelstate(int state, int *oldstate) { return 0; }

void __assert_func(const char *file, int line, const char *func, const char *failedexpr) {
    while(1);
}

// SDK missing symbols stubs
void esp_phy_init_clk() {}
void esp_reset_reason_early() {}
void esp_reset_reason_init() {}
void esp_pthread_init() {}
void chip_boot() {}
void esp_newlib_init() {}
// void esp_event_send() {} // Already in source
void esp_sleep_start() {}
void esp_task_wdt_reset() {}
void esp_sleep_lock() {}
void esp_sleep_unlock() {}
long long esp_timer_get_time() { return 0; }
// void esp_random() {} // Already in hw_random.c

void nvs_commit() {}
void nvs_flash_init() {}
void nvs_close() {}
void nvs_open() {}
void nvs_get_blob() {}
void nvs_set_blob() {}
void esp_crc8() {}

void Cache_Read_Enable_New() {}
void panicHandler() {}

// _xt_ext_panic is in xtensa_vectors.S

// More encryption stubs
void ccmp_encrypt() {}
void aes_ccm_ae() {}
void aes_ccm_ad() {}
