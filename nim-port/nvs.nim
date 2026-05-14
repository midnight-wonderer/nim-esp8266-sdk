
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
  ESP_ERR_NVS_PAGE_FULL* = 0x110f.esp_err_t

# Flash and CRC API
proc spi_flash_read*(src_addr: uint32, dest: pointer, size: uint32): esp_err_t {.importc, header: "spi_flash.h".}
proc spi_flash_write*(dest_addr: uint32, src: pointer, size: uint32): esp_err_t {.importc, header: "spi_flash.h".}
proc spi_flash_erase_sector*(sector: uint32): esp_err_t {.importc, header: "spi_flash.h".}
proc crc32_le*(crc: uint32, buf: pointer, len: uint32): uint32 {.importc, header: "esp_crc.h".}

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

proc calculateCrc32(item: var Item): uint32 =
  var res = 0xffffffff.uint32
  res = crc32_le(res, addr item.nsIndex, 4)
  res = crc32_le(res, addr item.key, 16)
  res = crc32_le(res, addr item.data, 8)
  return res

proc calculateCrc32(header: var PageHeader): uint32 =
  var res = 0xffffffff.uint32
  res = crc32_le(res, addr header.seqNumber, 24)
  return res

proc getEntryState(table: array[32, uint8], index: int): EntryState =
  let byteIdx = index div 4
  let bitShift = (index mod 4) * 2
  let val = (table[byteIdx] shr bitShift) and 0x3
  return cast[EntryState](val)

proc setEntryState(table: var array[32, uint8], index: int, state: EntryState) =
  let byteIdx = index div 4
  let bitShift = (index mod 4) * 2
  table[byteIdx] = (table[byteIdx] and not (0x3.uint8 shl bitShift)) or (state.uint8 shl bitShift)

proc findItem(nsIndex: uint8, datatype: uint8, key: string): (esp_err_t, Item, uint32, int) =
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
          var itemKey = ""
          for c in item.key: (if c == '\0': break; itemKey.add(c))
          if itemKey == key:
            if datatype == T_ANY.uint8 or item.datatype == datatype: return (ESP_OK, item, pageAddr, entryIdx)
            else: return (ESP_ERR_NVS_TYPE_MISMATCH, item, pageAddr, entryIdx)
  return (ESP_ERR_NVS_NOT_FOUND, Item(), 0, 0)

proc writeItem(nsIndex: uint8, datatype: uint8, key: string, data: array[8, uint8]): esp_err_t =
  var targetPageAddr = 0.uint32
  var targetEntryIdx = -1
  var targetPageHeader: PageHeader
  var targetEntryTable: array[32, uint8]
  for pageIdx in 0..<6:
    let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
    discard spi_flash_read(pageAddr, addr targetPageHeader, sizeof(targetPageHeader).uint32)
    if targetPageHeader.state == PS_UNINITIALIZED:
      targetPageHeader.state = PS_ACTIVE; targetPageHeader.seqNumber = 1; targetPageHeader.version = 0xfe
      for i in 0..<19: targetPageHeader.reserved[i] = 0xff
      targetPageHeader.crc32 = calculateCrc32(targetPageHeader)
      discard spi_flash_write(pageAddr, addr targetPageHeader, sizeof(targetPageHeader).uint32)
      for i in 0..<32: targetEntryTable[i] = 0xff
      discard spi_flash_write(pageAddr + ENTRY_TABLE_OFFSET, addr targetEntryTable, 32)
      targetPageAddr = pageAddr; targetEntryIdx = 0; break
    if targetPageHeader.state == PS_ACTIVE:
      discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr targetEntryTable, 32)
      for i in 0..<ENTRIES_PER_PAGE: (if getEntryState(targetEntryTable, i) == ES_EMPTY: (targetPageAddr = pageAddr; targetEntryIdx = i; break))
      if targetEntryIdx != -1: break
  if targetEntryIdx == -1: return ESP_ERR_NVS_NO_FREE_PAGES
  var item: Item
  item.nsIndex = nsIndex; item.datatype = datatype; item.span = 1; item.chunkIndex = 0xff
  for i in 0..<min(key.len, 15): item.key[i] = key[i]
  item.key[min(key.len, 15)] = '\0'; item.data = data; item.crc32 = calculateCrc32(item)
  let itemAddr = targetPageAddr + ENTRY_DATA_OFFSET + (targetEntryIdx.uint32 * ENTRY_SIZE)
  discard spi_flash_write(itemAddr, addr item, sizeof(item).uint32)
  setEntryState(targetEntryTable, targetEntryIdx, ES_WRITTEN)
  let wordIdx = targetEntryIdx div 4; let wordAddr = targetPageAddr + ENTRY_TABLE_OFFSET + (wordIdx.uint32 * 4)
  let wordData = cast[ptr array[8, uint32]](addr targetEntryTable)[wordIdx]
  discard spi_flash_write(wordAddr, addr wordData, 4); return ESP_OK

proc eraseOldItem(nsIndex: uint8, datatype: uint8, key: string) =
  let (res, _, pageAddr, entryIdx) = findItem(nsIndex, datatype, key)
  if res == ESP_OK:
    var entryTable: array[32, uint8]
    discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
    setEntryState(entryTable, entryIdx, ES_ERASED)
    let wordIdx = entryIdx div 4; let wordAddr = pageAddr + ENTRY_TABLE_OFFSET + (wordIdx.uint32 * 4)
    let wordData = cast[ptr array[8, uint32]](addr entryTable)[wordIdx]
    discard spi_flash_write(wordAddr, addr wordData, 4)

proc nvs_flash_init*(): esp_err_t {.exportc.} =
  return ESP_OK

proc nvs_open*(name: cstring, mode: int32, handle: ptr nvs_handle_t): esp_err_t {.exportc.} =
  let nameStr = $name
  if nameStr == "phy": (handle[] = 0x1234; return ESP_OK)
  let (res, item, _, _) = findItem(0, T_U8.uint8, nameStr)
  if res == ESP_OK: (handle[] = item.data[0].uint32; return ESP_OK)
  let newId: uint8 = 10; var d: array[8, uint8]; d[0] = newId
  discard writeItem(0, T_U8.uint8, nameStr, d); handle[] = newId.uint32; return ESP_OK

proc nvs_get_u8*(handle: nvs_handle_t, key: cstring, out_value: ptr uint8): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U8.uint8, $key)
  if res == ESP_OK: (out_value[] = item.data[0]; return ESP_OK)
  return res

proc nvs_set_u8*(handle: nvs_handle_t, key: cstring, value: uint8): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U8.uint8, $key)
  var d: array[8, uint8]; d[0] = value; return writeItem(nsIndex, T_U8.uint8, $key, d)

proc nvs_get_i8*(handle: nvs_handle_t, key: cstring, out_value: ptr int8): esp_err_t {.exportc.} =
  return nvs_get_u8(handle, key, cast[ptr uint8](out_value))

proc nvs_set_i8*(handle: nvs_handle_t, key: cstring, value: int8): esp_err_t {.exportc.} =
  return nvs_set_u8(handle, key, cast[uint8](value))

proc nvs_get_u16*(handle: nvs_handle_t, key: cstring, out_value: ptr uint16): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U16.uint8, $key)
  if res == ESP_OK: (copyMem(out_value, addr item.data[0], 2); return ESP_OK)
  return res

proc nvs_set_u16*(handle: nvs_handle_t, key: cstring, value: uint16): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U16.uint8, $key)
  var d: array[8, uint8]; copyMem(addr d[0], addr value, 2); return writeItem(nsIndex, T_U16.uint8, $key, d)

proc nvs_get_i16*(handle: nvs_handle_t, key: cstring, out_value: ptr int16): esp_err_t {.exportc.} =
  return nvs_get_u16(handle, key, cast[ptr uint16](out_value))

proc nvs_set_i16*(handle: nvs_handle_t, key: cstring, value: int16): esp_err_t {.exportc.} =
  return nvs_set_u16(handle, key, cast[uint16](value))

proc nvs_get_u32*(handle: nvs_handle_t, key: cstring, out_value: ptr uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U32.uint8, $key)
  if res == ESP_OK: (copyMem(out_value, addr item.data[0], 4); return ESP_OK)
  return res

proc nvs_set_u32*(handle: nvs_handle_t, key: cstring, value: uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U32.uint8, $key)
  var d: array[8, uint8]; copyMem(addr d[0], addr value, 4); return writeItem(nsIndex, T_U32.uint8, $key, d)

proc nvs_get_i32*(handle: nvs_handle_t, key: cstring, out_value: ptr int32): esp_err_t {.exportc.} =
  return nvs_get_u32(handle, key, cast[ptr uint32](out_value))

proc nvs_set_i32*(handle: nvs_handle_t, key: cstring, value: int32): esp_err_t {.exportc.} =
  return nvs_set_u32(handle, key, cast[uint32](value))

proc nvs_get_blob*(handle: nvs_handle_t, key: cstring, out_value: pointer, length: ptr uint32): esp_err_t {.exportc.} =
  if handle == 0x1234 and $key == "cal_data":
    if out_value == nil: (length[] = 128; return ESP_OK)
    if length[] >= 128: (var p = cast[ptr array[128, uint8]](out_value); for i in 0..<128: p[i] = 0; return ESP_OK)
  return ESP_ERR_NVS_NOT_FOUND

proc nvs_close*(handle: nvs_handle_t) {.exportc.} = discard
proc nvs_commit*(handle: nvs_handle_t): esp_err_t {.exportc.} = ESP_OK

proc nvs_erase_key*(handle: nvs_handle_t, key: cstring): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_ANY.uint8, $key); return ESP_OK

proc nvs_erase_all*(handle: nvs_handle_t): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  for pageIdx in 0..<6:
    let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
    var entryTable: array[32, uint8]; discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
    var modded = false
    for entryIdx in 0..<ENTRIES_PER_PAGE:
      if getEntryState(entryTable, entryIdx) == ES_WRITTEN:
        var item: Item; let itemAddr = pageAddr + ENTRY_DATA_OFFSET + (entryIdx.uint32 * ENTRY_SIZE)
        discard spi_flash_read(itemAddr, addr item, sizeof(item).uint32)
        if item.nsIndex == nsIndex: (setEntryState(entryTable, entryIdx, ES_ERASED); modded = true)
    if modded: (let p = cast[ptr array[8, uint32]](addr entryTable); for i in 0..<8: (let wa = pageAddr + ENTRY_TABLE_OFFSET + (i.uint32 * 4); var wd = p[i]; discard spi_flash_write(wa, addr wd, 4)))
  return ESP_OK
