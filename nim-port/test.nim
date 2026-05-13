# test.nim
import esp_rtos, strutils

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
  discard esp_wifi_set_mode(WIFI_MODE_STA)

  var wifi_cfg: wifi_config_t
  
  # Copy strings to array[uint8]
  for i, c in SSID:
    if i < 31: wifi_cfg.sta.ssid[i] = uint8(c)
  for i, c in PASS:
    if i < 63: wifi_cfg.sta.password[i] = uint8(c)

  discard esp_wifi_set_config(WIFI_IF_STA, addr wifi_cfg)
  discard esp_wifi_start()
  
  echo "Connecting to: ", SSID
  discard esp_wifi_connect()
  
  echo "Connect call issued. Waiting 10s for IP..."
  vTaskDelay(10000) # Wait for connection/IP (simple approach)

  let server_sock = lwip_socket(AF_INET, SOCK_STREAM, IPPROTO_IP)
  if server_sock < 0:
    echo "Failed to create socket!"
    return

  var addr_in: sockaddr_in
  addr_in.sin_family = uint8(AF_INET)
  addr_in.sin_port = htons(8080)
  addr_in.sin_addr.s_addr = uint32(INADDR_ANY)

  if lwip_bind(server_sock, cast[ptr sockaddr](addr addr_in), uint32(sizeof(sockaddr_in))) < 0:
    echo "Bind failed!"
    return

  if lwip_listen(server_sock, 5) < 0:
    echo "Listen failed!"
    return

  echo "TCP Server listening on port 8080..."

  while true:
    var client_addr: sockaddr
    var addr_len: uint32 = uint32(sizeof(sockaddr))
    let client_sock = lwip_accept(server_sock, addr client_addr, addr addr_len)
    
    if client_sock >= 0:
      echo "Client connected!"
      var buf: array[64, char]
      let bytes_rx = lwip_recv(client_sock, addr buf, 63, 0)
      
      if bytes_rx > 0:
        buf[bytes_rx] = '\0' # Null terminate
        let msg = $cast[cstring](addr buf)
        echo "Received: ", msg
        
        # Logic: If 'hello', respond 'world'. Discard if too long (already limited by 64)
        if msg.startsWith("hello"):
          let resp = "world\n"
          discard lwip_send(client_sock, cast[pointer](resp.cstring), uint32(resp.len), 0)
      
      discard lwip_close(client_sock)
      echo "Client disconnected."

