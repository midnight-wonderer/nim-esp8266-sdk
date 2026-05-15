# adc.nim
import esp_rtos

type
  adc_mode_t* = enum
    ADC_READ_TOUT_MODE = 0,
    ADC_READ_VDD_MODE,
    ADC_READ_MAX_MODE

  adc_config_t* {.importc: "adc_config_t", header: "driver/adc.h".} = object
    mode*: adc_mode_t
    clk_div*: uint8

proc adc_read*(data: ptr uint16): esp_err_t {.importc: "adc_read", header: "driver/adc.h".}
proc adc_read_fast*(data: ptr uint16, len: uint16): esp_err_t {.importc: "adc_read_fast", header: "driver/adc.h".}
proc adc_deinit*(): esp_err_t {.importc: "adc_deinit", header: "driver/adc.h".}
proc adc_init*(config: ptr adc_config_t): esp_err_t {.importc: "adc_init", header: "driver/adc.h".}
