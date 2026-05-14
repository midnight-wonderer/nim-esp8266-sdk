# test.nim
import esp_rtos, strutils
{.passC: "-include fix_mdns.h".}

# These can be set via -d:WIFI_SSID="name" and -d:WIFI_PASS="pass"
const SSID {.strdefine.} = "YOUR_SSID_HERE"
const PASS {.strdefine.} = "YOUR_PASS_HERE"

proc app_main*() {.exportc.} =
  echo "Nim Wi-Fi Connect Starting..."

  var init_cfg = wifi_init_config_t(
    magic: 0x1F2F3F4F,
    rx_buf_num: 16,
    rx_pkt_num: 7,
    tx_buf_num: 6,
    nvs_enable: 1
  )

  discard esp_wifi_init(addr init_cfg)
  discard esp_event_loop_create_default()
  discard esp_wifi_set_mode(WIFI_MODE_STA)
  
  var wifi_cfg: wifi_config_t
  # Copy SSID and PASS
  for i, c in SSID: wifi_cfg.sta.ssid[i] = byte(c)
  for i, c in PASS: wifi_cfg.sta.password[i] = byte(c)
  
  discard esp_wifi_set_config(WIFI_IF_STA, addr wifi_cfg)
  
  # Start Wi-Fi
  discard esp_wifi_start()
  discard esp_wifi_connect()
  
  # Init TCP/IP
  tcpip_adapter_init()
  
  # Setup mDNS
  echo "Starting mDNS..."
  discard mdns_init()
  discard mdns_hostname_set("nim-esp")
  discard mdns_instance_name_set("Nim ESP8266 Server")
  
  # Register our TCP server as a service
  discard mdns_service_add(nil, "_http", "_tcp", 8080, nil, 0)
  
  echo "Connect call issued. Waiting 10s for IP..."
  vTaskDelay(10000) # Wait for connection/IP (simple approach)

  let server_sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP)
  if server_sock < 0:
    echo "Failed to create socket!"
    return

  var addr_in: SockAddrIn
  addr_in.sin_family = uint8(AF_INET)
  addr_in.sin_port = htons(8080)
  addr_in.sin_addr.s_addr = uint32(INADDR_ANY)

  if `bind`(server_sock, addr addr_in, uint32(sizeof(SockAddrIn))) < 0:
    echo "Bind failed!"
    return

  if listen(server_sock, 5) < 0:
    echo "Listen failed!"
    return

  echo "TCP Server listening on port 8080..."

  while true:
    var client_sock = accept(server_sock, nil, nil)
    if client_sock >= 0:
      echo "New client connected!"
      var buffer: array[128, char]
      let bytes_received = recv(client_sock, addr buffer, buffer.len, 0)
      if bytes_received > 0:
        let msg = cast[string](buffer[0..<bytes_received])
        if msg.startsWith("hello"):
          discard send(client_sock, cstring("world\n"), 6, 0)
      
      discard close(client_sock)
    
    vTaskDelay(100)
