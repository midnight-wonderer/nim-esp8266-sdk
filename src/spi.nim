# spi.nim
import esp_rtos

type
  spi_host_t* = enum
    CSPI_HOST = 0,
    HSPI_HOST

  spi_clk_div_t* = enum
    SPI_2MHz_DIV = 40,
    SPI_4MHz_DIV = 20,
    SPI_5MHz_DIV = 16,
    SPI_8MHz_DIV = 10,
    SPI_10MHz_DIV = 8,
    SPI_16MHz_DIV = 5,
    SPI_20MHz_DIV = 4,
    SPI_40MHz_DIV = 2,
    SPI_80MHz_DIV = 1

  spi_mode_t* = enum
    SPI_MASTER_MODE = 0,
    SPI_SLAVE_MODE

  spi_intr_enable_t* {.importc: "spi_intr_enable_t", header: "driver/spi.h", union.} = object
    val*: uint32

  spi_interface_t* {.importc: "spi_interface_t", header: "driver/spi.h", union.} = object
    val*: uint32

  spi_event_callback_t* = proc (event: int32, arg: pointer) {.cdecl.}

  spi_config_t* {.importc: "spi_config_t", header: "driver/spi.h".} = object
    interface*: spi_interface_t
    intr_enable*: spi_intr_enable_t
    event_cb*: spi_event_callback_t
    mode*: spi_mode_t
    clk_div*: spi_clk_div_t

  spi_trans_bits_t* {.importc: "spi_trans_t::bits", header: "driver/spi.h", union.} = object
    val*: uint32

  spi_trans_t* {.importc: "spi_trans_t", header: "driver/spi.h".} = object
    cmd*: ptr uint16
    addr*: ptr uint32
    mosi*: ptr uint32
    miso*: ptr uint32
    bits*: uint32 # Actually a union in C, but we can treat as uint32 for simplicity or map it properly

proc spi_init*(host: spi_host_t, config: ptr spi_config_t): esp_err_t {.importc: "spi_init", header: "driver/spi.h".}
proc spi_deinit*(host: spi_host_t): esp_err_t {.importc: "spi_deinit", header: "driver/spi.h".}
proc spi_trans*(host: spi_host_t, trans: ptr spi_trans_t): esp_err_t {.importc: "spi_trans", header: "driver/spi.h".}
proc spi_set_clk_div*(host: spi_host_t, clk_div: ptr spi_clk_div_t): esp_err_t {.importc: "spi_set_clk_div", header: "driver/spi.h".}
proc spi_get_clk_div*(host: spi_host_t, clk_div: ptr spi_clk_div_t): esp_err_t {.importc: "spi_get_clk_div", header: "driver/spi.h".}
