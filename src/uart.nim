# uart.nim
import esp_rtos

type
  uart_port_t* = enum
    UART_NUM_0 = 0,
    UART_NUM_1 = 1,
    UART_NUM_MAX

  uart_word_length_t* = enum
    UART_DATA_5_BITS = 0,
    UART_DATA_6_BITS = 1,
    UART_DATA_7_BITS = 2,
    UART_DATA_8_BITS = 3

  uart_stop_bits_t* = enum
    UART_STOP_BITS_1 = 1,
    UART_STOP_BITS_1_5 = 2,
    UART_STOP_BITS_2 = 3

  uart_parity_t* = enum
    UART_PARITY_DISABLE = 0,
    UART_PARITY_EVEN = 2,
    UART_PARITY_ODD = 3

  uart_hw_flowcontrol_t* = enum
    UART_HW_FLOWCTRL_DISABLE = 0,
    UART_HW_FLOWCTRL_RTS = 1,
    UART_HW_FLOWCTRL_CTS = 2,
    UART_HW_FLOWCTRL_CTS_RTS = 3

  uart_config_t* {.importc: "uart_config_t", header: "driver/uart.h".} = object
    baud_rate*: int32
    data_bits*: uart_word_length_t
    parity*: uart_parity_t
    stop_bits*: uart_stop_bits_t
    flow_ctrl*: uart_hw_flowcontrol_t
    rx_flow_ctrl_thresh*: uint8

proc uart_param_config*(uart_num: uart_port_t, uart_conf: ptr uart_config_t): esp_err_t {.importc: "uart_param_config", header: "driver/uart.h".}
proc uart_driver_install*(uart_num: uart_port_t, rx_buffer_size: int32, tx_buffer_size: int32, queue_size: int32, uart_queue: pointer, no_use: int32): esp_err_t {.importc: "uart_driver_install", header: "driver/uart.h".}
proc uart_driver_delete*(uart_num: uart_port_t): esp_err_t {.importc: "uart_driver_delete", header: "driver/uart.h".}
proc uart_write_bytes*(uart_num: uart_port_t, src: pointer, size: uint32): int32 {.importc: "uart_write_bytes", header: "driver/uart.h".}
proc uart_read_bytes*(uart_num: uart_port_t, buf: pointer, length: uint32, ticks_to_wait: uint32): int32 {.importc: "uart_read_bytes", header: "driver/uart.h".}
proc uart_flush*(uart_num: uart_port_t): esp_err_t {.importc: "uart_flush", header: "driver/uart.h".}
proc uart_set_baudrate*(uart_num: uart_port_t, baudrate: uint32): esp_err_t {.importc: "uart_set_baudrate", header: "driver/uart.h".}
proc uart_get_baudrate*(uart_num: uart_port_t, baudrate: ptr uint32): esp_err_t {.importc: "uart_get_baudrate", header: "driver/uart.h".}
