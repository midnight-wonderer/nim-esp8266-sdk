# pwm.nim
import esp_rtos

proc pwm_init*(period: uint32, duties: ptr uint32, channel_num: uint8, pin_num: ptr uint32): esp_err_t {.importc: "pwm_init", header: "driver/pwm.h".}
proc pwm_deinit*(): esp_err_t {.importc: "pwm_deinit", header: "driver/pwm.h".}
proc pwm_set_duty*(channel_num: uint8, duty: uint32): esp_err_t {.importc: "pwm_set_duty", header: "driver/pwm.h".}
proc pwm_get_duty*(channel_num: uint8, duty_p: ptr uint32): esp_err_t {.importc: "pwm_get_duty", header: "driver/pwm.h".}
proc pwm_set_period*(period: uint32): esp_err_t {.importc: "pwm_set_period", header: "driver/pwm.h".}
proc pwm_get_period*(period_p: ptr uint32): esp_err_t {.importc: "pwm_get_period", header: "driver/pwm.h".}
proc pwm_start*(): esp_err_t {.importc: "pwm_start", header: "driver/pwm.h".}
proc pwm_stop*(stop_level_mask: uint32): esp_err_t {.importc: "pwm_stop", header: "driver/pwm.h".}
proc pwm_set_duties*(duties: ptr uint32): esp_err_t {.importc: "pwm_set_duties", header: "driver/pwm.h".}
proc pwm_set_phase*(channel_num: uint8, phase: float32): esp_err_t {.importc: "pwm_set_phase", header: "driver/pwm.h".}
proc pwm_set_phases*(phases: ptr float32): esp_err_t {.importc: "pwm_set_phases", header: "driver/pwm.h".}
proc pwm_get_phase*(channel_num: uint8, phase_p: ptr float32): esp_err_t {.importc: "pwm_get_phase", header: "driver/pwm.h".}
proc pwm_set_period_duties*(period: uint32, duties: ptr uint32): esp_err_t {.importc: "pwm_set_period_duties", header: "driver/pwm.h".}
proc pwm_set_channel_invert*(channel_mask: uint16): esp_err_t {.importc: "pwm_set_channel_invert", header: "driver/pwm.h".}
proc pwm_clear_channel_invert*(channel_mask: uint16): esp_err_t {.importc: "pwm_clear_channel_invert", header: "driver/pwm.h".}
