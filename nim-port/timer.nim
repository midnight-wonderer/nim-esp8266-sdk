# Configuration constants from sdkconfig.h
const
  CONFIG_FREERTOS_HZ = 100
  CONFIG_ESP8266_DEFAULT_CPU_FREQ_MHZ = 80
  
type
  esp_err_t* = int32
  
  esp_timer_cb_t* = proc (arg: pointer) {.cdecl.}
  
  esp_timer_dispatch_t* = enum
    ESP_TIMER_TASK = 0
    
  # Struct mirror for C compatibility
  esp_timer_create_args_t* = object
    callback*: esp_timer_cb_t
    arg*: pointer
    dispatch_method*: esp_timer_dispatch_t
    name*: cstring

  esp_timer_state_t = enum
    ESP_TIMER_INIT = 0,
    ESP_TIMER_ONCE,
    ESP_TIMER_CYCLE,
    ESP_TIMER_STOP,
    ESP_TIMER_DELETE

  esp_timer_obj = object
    os_timer*: pointer # TimerHandle_t
    callback*: esp_timer_cb_t
    arg*: pointer
    state*: esp_timer_state_t

  esp_timer_handle_t* = ptr esp_timer_obj

# FreeRTOS Timer API Bindings
proc xTimerCreate(pcTimerName: cstring, xTimerPeriodInTicks: uint32, uxAutoReload: uint32, pvTimerID: pointer, pxCallbackFunction: pointer): pointer {.importc: "xTimerCreate", header: "freertos/timers.h".}
proc xTimerStart(xTimer: pointer, xTicksToWait: uint32): int32 {.importc: "xTimerStart", header: "freertos/timers.h".}
proc xTimerStop(xTimer: pointer, xTicksToWait: uint32): int32 {.importc: "xTimerStop", header: "freertos/timers.h".}
proc xTimerDelete(xTimer: pointer, xTicksToWait: uint32): int32 {.importc: "xTimerDelete", header: "freertos/timers.h".}
proc xTimerChangePeriod(xTimer: pointer, xNewPeriod: uint32, xTicksToWait: uint32): int32 {.importc: "xTimerChangePeriod", header: "freertos/timers.h".}
proc xTimerReset(xTimer: pointer, xTicksToWait: uint32): int32 {.importc: "xTimerReset", header: "freertos/timers.h".}
proc pvTimerGetTimerID(xTimer: pointer): pointer {.importc: "pvTimerGetTimerID", header: "freertos/timers.h".}

const 
  pdFALSE = 0.uint32
  pdTRUE = 1.uint32
  portMAX_DELAY = 0xFFFFFFFF.uint32

# The actual callback wrapper that FreeRTOS executes
proc esp_timer_callback(xTimer: pointer) {.cdecl.} =
  let timer = cast[esp_timer_handle_t](pvTimerGetTimerID(xTimer))
  if timer == nil: return
  
  if timer.callback != nil:
    timer.callback(timer.arg)
    
  case timer.state
  of ESP_TIMER_CYCLE:
    # Manual reload to match C implementation logic
    discard xTimerReset(timer.os_timer, portMAX_DELAY)
  of ESP_TIMER_ONCE:
    discard xTimerStop(timer.os_timer, portMAX_DELAY)
    timer.state = ESP_TIMER_STOP
  of ESP_TIMER_DELETE:
    discard xTimerDelete(timer.os_timer, portMAX_DELAY)
    dealloc(timer)
  else:
    discard

# --- Public API Implementation (Exported to C) ---

proc esp_timer_init*(): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  return 0 # ESP_OK

proc esp_timer_deinit*(): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  return 0 # ESP_OK

proc esp_timer_create*(create_args: ptr esp_timer_create_args_t, out_handle: ptr esp_timer_handle_t): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  if create_args == nil or out_handle == nil: return -1
  
  let timer = cast[esp_timer_handle_t](alloc0(sizeof(esp_timer_obj)))
  if timer == nil: return -1 # ESP_ERR_NO_MEM
  
  timer.callback = create_args.callback
  timer.arg = create_args.arg
  timer.state = ESP_TIMER_INIT
  
  # Create a FreeRTOS timer. We set pdFALSE (one-shot) and handle cycling manually in the callback.
  timer.os_timer = xTimerCreate(create_args.name, 100, pdFALSE, timer, esp_timer_callback)
  
  if timer.os_timer == nil:
    dealloc(timer)
    return -1
    
  out_handle[] = timer
  return 0

proc esp_timer_start_once*(timer: esp_timer_handle_t, timeout_us: uint64): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  if timer == nil: return -1
  
  let ticks = uint32(timeout_us div (1000000 div CONFIG_FREERTOS_HZ))
  if ticks == 0: return -1
  
  if xTimerChangePeriod(timer.os_timer, ticks, portMAX_DELAY) == 1:
    timer.state = ESP_TIMER_ONCE
    return 0
  return -1

proc esp_timer_start_periodic*(timer: esp_timer_handle_t, period: uint64): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  if timer == nil: return -1
  
  let ticks = uint32(period div (1000000 div CONFIG_FREERTOS_HZ))
  if ticks == 0: return -1
  
  if xTimerChangePeriod(timer.os_timer, ticks, portMAX_DELAY) == 1:
    timer.state = ESP_TIMER_CYCLE
    return 0
  return -1

proc esp_timer_stop*(timer: esp_timer_handle_t): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  if timer == nil: return -1
  if xTimerStop(timer.os_timer, portMAX_DELAY) == 1:
    timer.state = ESP_TIMER_STOP
    return 0
  return -1

proc esp_timer_delete*(timer: esp_timer_handle_t): esp_err_t {.exportc, codegenDecl: "esp_err_t $2$3".} =
  if timer == nil: return -1
  if xTimerDelete(timer.os_timer, portMAX_DELAY) == 1:
    dealloc(timer)
    return 0
  return -1

# Timekeeping Implementation
var g_esp_os_us {.importc.}: uint64

proc soc_get_ccount(): uint32 {.inline.} =
  asm """
    rsr %0, ccount
    :"=r"(`result`)
  """

proc esp_timer_get_time*(): int64 {.exportc, codegenDecl: "int64_t $2$3".} =
  return cast[int64](g_esp_os_us + (soc_get_ccount() div CONFIG_ESP8266_DEFAULT_CPU_FREQ_MHZ).uint64)
