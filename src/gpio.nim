# gpio.nim
import esp_rtos

type
  gpio_num_t* = enum
    GPIO_NUM_0 = 0,
    GPIO_NUM_1 = 1,
    GPIO_NUM_2 = 2,
    GPIO_NUM_3 = 3,
    GPIO_NUM_4 = 4,
    GPIO_NUM_5 = 5,
    GPIO_NUM_6 = 6,
    GPIO_NUM_7 = 7,
    GPIO_NUM_8 = 8,
    GPIO_NUM_9 = 9,
    GPIO_NUM_10 = 10,
    GPIO_NUM_11 = 11,
    GPIO_NUM_12 = 12,
    GPIO_NUM_13 = 13,
    GPIO_NUM_14 = 14,
    GPIO_NUM_15 = 15,
    GPIO_NUM_16 = 16,
    GPIO_NUM_MAX = 17

  gpio_int_type_t* = enum
    GPIO_INTR_DISABLE = 0,
    GPIO_INTR_POSEDGE = 1,
    GPIO_INTR_NEGEDGE = 2,
    GPIO_INTR_ANYEDGE = 3,
    GPIO_INTR_LOW_LEVEL = 4,
    GPIO_INTR_HIGH_LEVEL = 5,
    GPIO_INTR_MAX

  gpio_mode_t* = enum
    GPIO_MODE_DISABLE = 0,
    GPIO_MODE_INPUT = 1,
    GPIO_MODE_OUTPUT = 2,
    GPIO_MODE_OUTPUT_OD = 6 # (BIT(1) | BIT(2))

  gpio_pull_mode_t* = enum
    GPIO_PULLUP_ONLY = 0,
    GPIO_PULLDOWN_ONLY = 1,
    GPIO_FLOATING = 2

  gpio_pullup_t* = enum
    GPIO_PULLUP_DISABLE = 0x0,
    GPIO_PULLUP_ENABLE = 0x1

  gpio_pulldown_t* = enum
    GPIO_PULLDOWN_DISABLE = 0x0,
    GPIO_PULLDOWN_ENABLE = 0x1

  gpio_config_t* {.importc: "gpio_config_t", header: "driver/gpio.h".} = object
    pin_bit_mask*: uint32
    mode*: gpio_mode_t
    pull_up_en*: gpio_pullup_t
    pull_down_en*: gpio_pulldown_t
    intr_type*: gpio_int_type_t

  gpio_isr_t* = proc (arg: pointer) {.noconv.}

proc gpio_config*(gpio_cfg: ptr gpio_config_t): esp_err_t {.importc: "gpio_config", header: "driver/gpio.h".}
proc gpio_set_intr_type*(gpio_num: gpio_num_t, intr_type: gpio_int_type_t): esp_err_t {.importc: "gpio_set_intr_type", header: "driver/gpio.h".}
proc gpio_set_level*(gpio_num: gpio_num_t, level: uint32): esp_err_t {.importc: "gpio_set_level", header: "driver/gpio.h".}
proc gpio_get_level*(gpio_num: gpio_num_t): int32 {.importc: "gpio_get_level", header: "driver/gpio.h".}
proc gpio_set_direction*(gpio_num: gpio_num_t, mode: gpio_mode_t): esp_err_t {.importc: "gpio_set_direction", header: "driver/gpio.h".}
proc gpio_set_pull_mode*(gpio_num: gpio_num_t, pull: gpio_pull_mode_t): esp_err_t {.importc: "gpio_set_pull_mode", header: "driver/gpio.h".}
proc gpio_wakeup_enable*(gpio_num: gpio_num_t, intr_type: gpio_int_type_t): esp_err_t {.importc: "gpio_wakeup_enable", header: "driver/gpio.h".}
proc gpio_wakeup_disable*(gpio_num: gpio_num_t): esp_err_t {.importc: "gpio_wakeup_disable", header: "driver/gpio.h".}
proc gpio_isr_register*(fn: gpio_isr_t, arg: pointer, no_use: int32, handle: pointer): esp_err_t {.importc: "gpio_isr_register", header: "driver/gpio.h".}
proc gpio_pullup_en*(gpio_num: gpio_num_t): esp_err_t {.importc: "gpio_pullup_en", header: "driver/gpio.h".}
proc gpio_pullup_dis*(gpio_num: gpio_num_t): esp_err_t {.importc: "gpio_pullup_dis", header: "driver/gpio.h".}
proc gpio_pulldown_en*(gpio_num: gpio_num_t): esp_err_t {.importc: "gpio_pulldown_en", header: "driver/gpio.h".}
proc gpio_pulldown_dis*(gpio_num: gpio_num_t): esp_err_t {.importc: "gpio_pulldown_dis", header: "driver/gpio.h".}
proc gpio_install_isr_service*(no_use: int32): esp_err_t {.importc: "gpio_install_isr_service", header: "driver/gpio.h".}
proc gpio_uninstall_isr_service*() {.importc: "gpio_uninstall_isr_service", header: "driver/gpio.h".}
proc gpio_isr_handler_add*(gpio_num: gpio_num_t, isr_handler: gpio_isr_t, args: pointer): esp_err_t {.importc: "gpio_isr_handler_add", header: "driver/gpio.h".}
proc gpio_isr_handler_remove*(gpio_num: gpio_num_t): esp_err_t {.importc: "gpio_isr_handler_remove", header: "driver/gpio.h".}
