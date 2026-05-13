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
void esp_reset_reason_early() {}
void esp_reset_reason_init() {}
void esp_pthread_init() {}
void chip_boot() {}
void esp_newlib_init() {}
void esp_sleep_start() {}
void esp_task_wdt_reset() {}
void esp_sleep_lock() {}
void esp_sleep_unlock() {}
long long esp_timer_get_time() { return 0; }

// NVS stubs (better signatures)
int nvs_flash_init(void) { return 0; }
int nvs_open(const char* name, int open_mode, uint32_t *out_handle) { 
    *out_handle = 1; 
    return 0; 
}
void nvs_close(uint32_t handle) {}
int nvs_commit(uint32_t handle) { return 0; }
int nvs_get_blob(uint32_t handle, const char* key, void* out_value, size_t* length) {
    return 0x1102; // ESP_ERR_NVS_NOT_FOUND
}
int nvs_set_blob(uint32_t handle, const char* key, const void* value, size_t length) {
    return 0;
}
int nvs_get_u8(uint32_t handle, const char* key, uint8_t* out_value) { return 0x1102; }
int nvs_set_u8(uint32_t handle, const char* key, uint8_t value) { return 0; }
int nvs_get_i32(uint32_t handle, const char* key, int32_t* out_value) { return 0x1102; }
int nvs_set_i32(uint32_t handle, const char* key, int32_t value) { return 0; }
int nvs_get_str(uint32_t handle, const char* key, char* out_value, size_t* length) { return 0x1102; }
int nvs_set_str(uint32_t handle, const char* key, const char* value) { return 0; }

// Storage / Partition stubs
void* esp_partition_find_first(int type, int subtype, const char* label) { return NULL; }
int esp_partition_read(void* partition, size_t src_offset, void* dst, size_t size) { return 0; }
int esp_partition_write(void* partition, size_t dst_offset, const void* src, size_t size) { return 0; }
int esp_partition_erase_range(void* partition, size_t offset, size_t size) { return 0; }

// Power Management
int esp_sleep_enable_timer_wakeup(uint64_t time_in_us) { return 0; }
int esp_light_sleep_start(void) { return 0; }

void uart_tx_wait_idle(int uart) {}

uint8_t esp_crc8(const uint8_t *src, size_t len) { return 0; }

void Cache_Read_Enable_New() {}
void panicHandler() {}
