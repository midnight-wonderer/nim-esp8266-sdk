# i2c.nim
import esp_rtos, gpio

type
  i2c_mode_t* = enum
    I2C_MODE_MASTER = 0,
    I2C_MODE_MAX

  i2c_rw_t* = enum
    I2C_MASTER_WRITE = 0,
    I2C_MASTER_READ

  i2c_opmode_t* = enum
    I2C_CMD_RESTART = 0,
    I2C_CMD_WRITE,
    I2C_CMD_READ,
    I2C_CMD_STOP

  i2c_port_t* = enum
    I2C_NUM_0 = 0,
    I2C_NUM_MAX

  i2c_ack_type_t* = enum
    I2C_MASTER_ACK = 0x0,
    I2C_MASTER_NACK = 0x1,
    I2C_MASTER_LAST_NACK = 0x2,
    I2C_MASTER_ACK_MAX

  i2c_config_t* {.importc: "i2c_config_t", header: "driver/i2c.h".} = object
    mode*: i2c_mode_t
    sda_io_num*: gpio_num_t
    sda_pullup_en*: gpio_pullup_t
    scl_io_num*: gpio_num_t
    scl_pullup_en*: gpio_pullup_t
    clk_stretch_tick*: uint32

  i2c_cmd_handle_t* = pointer

proc i2c_driver_install*(i2c_num: i2c_port_t, mode: i2c_mode_t): esp_err_t {.importc: "i2c_driver_install", header: "driver/i2c.h".}
proc i2c_driver_delete*(i2c_num: i2c_port_t): esp_err_t {.importc: "i2c_driver_delete", header: "driver/i2c.h".}
proc i2c_param_config*(i2c_num: i2c_port_t, i2c_conf: ptr i2c_config_t): esp_err_t {.importc: "i2c_param_config", header: "driver/i2c.h".}
proc i2c_set_pin*(i2c_num: i2c_port_t, sda_io_num: int32, scl_io_num: int32, sda_pullup_en: gpio_pullup_t, scl_pullup_en: gpio_pullup_t, mode: i2c_mode_t): esp_err_t {.importc: "i2c_set_pin", header: "driver/i2c.h".}
proc i2c_cmd_link_create*(): i2c_cmd_handle_t {.importc: "i2c_cmd_link_create", header: "driver/i2c.h".}
proc i2c_cmd_link_delete*(cmd_handle: i2c_cmd_handle_t) {.importc: "i2c_cmd_link_delete", header: "driver/i2c.h".}
proc i2c_master_start*(cmd_handle: i2c_cmd_handle_t): esp_err_t {.importc: "i2c_master_start", header: "driver/i2c.h".}
proc i2c_master_write_byte*(cmd_handle: i2c_cmd_handle_t, data: uint8, ack_en: bool): esp_err_t {.importc: "i2c_master_write_byte", header: "driver/i2c.h".}
proc i2c_master_write*(cmd_handle: i2c_cmd_handle_t, data: ptr uint8, data_len: uint32, ack_en: bool): esp_err_t {.importc: "i2c_master_write", header: "driver/i2c.h".}
proc i2c_master_read_byte*(cmd_handle: i2c_cmd_handle_t, data: ptr uint8, ack: i2c_ack_type_t): esp_err_t {.importc: "i2c_master_read_byte", header: "driver/i2c.h".}
proc i2c_master_read*(cmd_handle: i2c_cmd_handle_t, data: ptr uint8, data_len: uint32, ack: i2c_ack_type_t): esp_err_t {.importc: "i2c_master_read", header: "driver/i2c.h".}
proc i2c_master_stop*(cmd_handle: i2c_cmd_handle_t): esp_err_t {.importc: "i2c_master_stop", header: "driver/i2c.h".}
proc i2c_master_cmd_begin*(i2c_num: i2c_port_t, cmd_handle: i2c_cmd_handle_t, ticks_to_wait: uint32): esp_err_t {.importc: "i2c_master_cmd_begin", header: "driver/i2c.h".}
