# test.nim
import esp_rtos

proc app_main*() {.exportc.} =
  echo "Hello from Nim app_main on ESP8266!"
  discard esp_wifi_start()
