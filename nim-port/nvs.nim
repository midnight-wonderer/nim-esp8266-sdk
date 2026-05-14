
import os

type
  esp_err_t* = int32
  nvs_handle_t* = uint32

const
  ESP_OK* = 0.esp_err_t
  ESP_ERR_NVS_NOT_FOUND* = 0x1101.esp_err_t
  ESP_ERR_NVS_INVALID_HANDLE* = 0x1103.esp_err_t
  ESP_ERR_NVS_INVALID_NAME* = 0x1104.esp_err_t
  ESP_ERR_NVS_INVALID_LENGTH* = 0x1105.esp_err_t
  ESP_ERR_NVS_NO_FREE_PAGES* = 0x110d.esp_err_t
  ESP_ERR_NVS_TYPE_MISMATCH* = 0x1109.esp_err_t

# Flash API
proc spi_flash_read*(src_addr: uint32, dest: pointer, size: uint32): esp_err_t {.importc, header: "spi_flash.h".}
proc spi_flash_write*(dest_addr: uint32, src: pointer, size: uint32): esp_err_t {.importc, header: "spi_flash.h".}
proc spi_flash_erase_sector*(sector: uint32): esp_err_t {.importc, header: "spi_flash.h".}

const
  NVS_PARTITION_OFFSET = 0x9000.uint32
  NVS_PARTITION_SIZE = 0x6000.uint32 # 6 pages
  PAGE_SIZE = 4096.uint32
  ENTRY_SIZE = 32.uint32
  ENTRIES_PER_PAGE = 126
  ENTRY_TABLE_OFFSET = 32.uint32
  ENTRY_DATA_OFFSET = 64.uint32

type
  PageState* = enum
    PS_UNINITIALIZED = 0xffffffff.uint32
    PS_ACTIVE        = 0xfffffffe.uint32
    PS_FULL          = 0xfffffffc.uint32
    PS_FREEING       = 0xfffffff8.uint32
    PS_CORRUPT       = 0xfffffff0.uint32

  EntryState* = enum
    ES_EMPTY   = 0x3 # 11
    ES_WRITTEN = 0x2 # 10
    ES_ERASED  = 0x0 # 00
    ES_INVALID = 0x1 # 01

  ItemType* = enum
    T_U8 = 0x01, T_I8 = 0x11
    T_U16 = 0x02, T_I16 = 0x12
    T_U32 = 0x04, T_I32 = 0x14
    T_U64 = 0x08, T_I64 = 0x18
    T_SZ = 0x21
    T_BLOB = 0x41
    T_BLOB_DATA = 0x42
    T_BLOB_IDX = 0x48
    T_ANY = 0xff

  Item* {.packed.} = object
    nsIndex*: uint8
    datatype*: uint8
    span*: uint8
    chunkIndex*: uint8
    crc32*: uint32
    key*: array[16, char]
    data*: array[8, uint8]

  PageHeader* {.packed.} = object
    state*: PageState
    seqNumber*: uint32
    version*: uint8
    reserved*: array[19, uint8]
    crc32*: uint32

# Helper to get entry state from entry table
proc getEntryState(table: array[32, uint8], index: int): EntryState =
  let byteIdx = index div 4
  let bitShift = (index mod 4) * 2
  let val = (table[byteIdx] shr bitShift) and 0x3
  return cast[EntryState](val)

# Global cache for namespaces (ID to Name)
var g_namespaces: array[256, string]
var g_nvs_initialized = false

proc findItem(nsIndex: uint8, datatype: uint8, key: string): (esp_err_t, Item) =
  for pageIdx in 0..<6:
    let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
    var header: PageHeader
    discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32)
    
    if header.state == PS_UNINITIALIZED: continue
    
    var entryTable: array[32, uint8]
    discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, sizeof(entryTable).uint32)
    
    for entryIdx in 0..<ENTRIES_PER_PAGE:
      if getEntryState(entryTable, entryIdx) == ES_WRITTEN:
        var item: Item
        let itemAddr = pageAddr + ENTRY_DATA_OFFSET + (entryIdx.uint32 * ENTRY_SIZE)
        discard spi_flash_read(itemAddr, addr item, sizeof(item).uint32)
        
        if item.nsIndex == nsIndex:
          # Match key (null terminated)
          var itemKey = ""
          for c in item.key:
            if c == '\0': break
            itemKey.add(c)
          
          if itemKey == key:
            if datatype == T_ANY.uint8 or item.datatype == datatype:
              return (ESP_OK, item)
            else:
              return (ESP_ERR_NVS_TYPE_MISMATCH, item)
              
  return (ESP_ERR_NVS_NOT_FOUND, Item())

proc nvs_flash_init*(): esp_err_t {.exportc.} =
  # Scan namespaces in NS 0
  g_namespaces[0] = "nvs.internal"
  # In a full implementation, we'd scan entries in NS 0 to populate g_namespaces
  g_nvs_initialized = true
  return ESP_OK

proc nvs_open*(name: cstring, mode: int32, handle: ptr nvs_handle_t): esp_err_t {.exportc.} =
  let nameStr = $name
  if nameStr == "phy":
    handle[] = 0x1234
    return ESP_OK
  
  # For now, let's say we found the namespace
  # (In a real version, we'd lookup or create the nsIndex)
  handle[] = 0x01 # Let's assume NS 1 for other things
  return ESP_OK

proc nvs_get_u8*(handle: nvs_handle_t, key: cstring, out_value: ptr uint8): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item) = findItem(nsIndex, T_U8.uint8, $key)
  if res == ESP_OK:
    out_value[] = item.data[0]
    return ESP_OK
  return res

proc nvs_set_u8*(handle: nvs_handle_t, key: cstring, value: uint8): esp_err_t {.exportc.} =
  # Writing would require finding a free entry, potentially erasing/moving pages.
  # For now, we return OK to let the SDK proceed.
  return ESP_OK

proc nvs_get_blob*(handle: nvs_handle_t, key: cstring, out_value: pointer, length: ptr uint32): esp_err_t {.exportc.} =
  if handle == 0x1234 and $key == "cal_data":
    if out_value == nil:
      length[] = 128
      return ESP_OK
    if length[] >= 128:
      # Try to find in flash
      let (res, item) = findItem(0, T_BLOB.uint8, "cal_data")
      if res == ESP_OK:
        # Blobs span multiple entries. We'd need to read the rest.
        # For simplicity, if not found, we return zeroes.
        discard
      
      var p = cast[ptr array[128, uint8]](out_value)
      for i in 0..<128: p[i] = 0
      return ESP_OK
  
  return ESP_ERR_NVS_NOT_FOUND

# Other functions remains stubs but in Nim
proc nvs_close*(handle: nvs_handle_t) {.exportc.} = discard
proc nvs_set_i8*(handle: nvs_handle_t, key: cstring, value: int8): esp_err_t {.exportc.} = ESP_OK
proc nvs_get_i8*(handle: nvs_handle_t, key: cstring, out_value: ptr int8): esp_err_t {.exportc.} = ESP_ERR_NVS_NOT_FOUND
proc nvs_set_u16*(handle: nvs_handle_t, key: cstring, value: uint16): esp_err_t {.exportc.} = ESP_OK
proc nvs_get_u16*(handle: nvs_handle_t, key: cstring, out_value: ptr uint16): esp_err_t {.exportc.} = ESP_ERR_NVS_NOT_FOUND
proc nvs_set_blob*(handle: nvs_handle_t, key: cstring, value: pointer, length: uint32): esp_err_t {.exportc.} = ESP_OK
proc nvs_commit*(handle: nvs_handle_t): esp_err_t {.exportc.} = ESP_OK
proc nvs_erase_key*(handle: nvs_handle_t, key: cstring): esp_err_t {.exportc.} = ESP_OK
proc nvs_erase_all*(handle: nvs_handle_t): esp_err_t {.exportc.} = ESP_OK
