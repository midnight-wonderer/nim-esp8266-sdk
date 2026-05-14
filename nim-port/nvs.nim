# NVS Implementation in Nim
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
  NVS_PARTITION_SIZE = 0x6000.uint32 # 24 KB
  PAGE_SIZE = 4096.uint32
  NUM_PAGES = (NVS_PARTITION_SIZE div PAGE_SIZE).int
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

proc writeItem(nsIndex: uint8, datatype: uint8, key: string, data: pointer, length: uint32, chunkIndex: uint8 = 0xff): esp_err_t
proc compactPage(srcIdx: int, destIdx: int, nextSeq: uint32): esp_err_t

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

proc verifyPage(pageAddr: uint32): bool =
  var header: PageHeader
  discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32)
  if header.state == PS_UNINITIALIZED: return true
  if header.state == PS_CORRUPT: return false
  let calculatedCrc = calculateCrc32(header)
  return header.crc32 == calculatedCrc

proc findActivePage(): (int, uint32) =
  var maxSeq = 0.uint32
  var activeIdx = -1
  var firstUninit = -1

  for i in 0..<NUM_PAGES:
    let pageAddr = NVS_PARTITION_OFFSET + (i.uint32 * PAGE_SIZE)
    var header: PageHeader
    discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32)
    
    if header.state == PS_ACTIVE:
      if header.seqNumber >= maxSeq:
        maxSeq = header.seqNumber
        activeIdx = i.int
    elif header.state == PS_UNINITIALIZED and firstUninit == -1:
      firstUninit = i.int
      
  if activeIdx != -1:
    return (activeIdx, maxSeq)
  
  return (firstUninit, maxSeq)

proc initializePage(pageIdx: int, seqNumber: uint32): esp_err_t =
  let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
  discard spi_flash_erase_sector(pageAddr div PAGE_SIZE)
  
  var header: PageHeader
  header.state = PS_ACTIVE
  header.seqNumber = seqNumber
  header.version = 0xfe
  for i in 0..<19: header.reserved[i] = 0xff
  header.crc32 = calculateCrc32(header)
  
  discard spi_flash_write(pageAddr, addr header, sizeof(header).uint32)
  
  var entryTable: array[32, uint8]
  for i in 0..<32: entryTable[i] = 0xff
  discard spi_flash_write(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
  
  return ESP_OK

proc markPageFull(pageIdx: int): esp_err_t =
  let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
  var header: PageHeader
  discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32)
  header.state = PS_FULL
  # We don't strictly need to update CRC if we only care about state, 
  # but original NVS includes everything in CRC. 
  # For simplicity in this "breaking" version, we just update the state word.
  discard spi_flash_write(pageAddr, addr header.state, 4)
  return ESP_OK

proc findItem(nsIndex: uint8, datatype: uint8, key: string, chunkIndex: uint8 = 0xff): (esp_err_t, Item, uint32, int) =
  # Scan all pages to find the item
  for pageIdx in 0..<NUM_PAGES:
    let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
    var header: PageHeader
    discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32)
    if header.state == PS_UNINITIALIZED or header.state == PS_CORRUPT: continue
    
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
            if chunkIndex != 0xfe and item.chunkIndex != chunkIndex: continue
            if datatype == T_ANY.uint8 or item.datatype == datatype: return (ESP_OK, item, pageAddr, entryIdx)
            else: return (ESP_ERR_NVS_TYPE_MISMATCH, item, pageAddr, entryIdx)
  return (ESP_ERR_NVS_NOT_FOUND, Item(), 0, 0)

proc findConsecutiveEntries(table: array[32, uint8], span: int): int =
  var count = 0
  for i in 0..<ENTRIES_PER_PAGE:
    if getEntryState(table, i) == ES_EMPTY:
      count += 1
      if count == span: return i - span + 1
    else:
      count = 0
  return -1

proc eraseOldItem(nsIndex: uint8, datatype: uint8, key: string) =
  for pageIdx in 0..<NUM_PAGES:
    let pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
    var entryTable: array[32, uint8]; discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
    var modified = false
    for entryIdx in 0..<ENTRIES_PER_PAGE:
      if getEntryState(entryTable, entryIdx) == ES_WRITTEN:
        var item: Item; let itemAddr = pageAddr + ENTRY_DATA_OFFSET + (entryIdx.uint32 * ENTRY_SIZE)
        discard spi_flash_read(itemAddr, addr item, sizeof(item).uint32)
        if item.nsIndex == nsIndex and (datatype == T_ANY.uint8 or item.datatype == datatype):
           var itemKey = ""
           for c in item.key: (if c == '\0': break; itemKey.add(c))
           if itemKey == key:
             for s in 0..<item.span.int: setEntryState(entryTable, entryIdx + s, ES_ERASED)
             modified = true
    if modified:
      for w in 0..<8:
        let wordAddr = pageAddr + ENTRY_TABLE_OFFSET + (w.uint32 * 4)
        let wordData = cast[ptr array[8, uint32]](addr entryTable)[w]
        discard spi_flash_write(wordAddr, addr wordData, 4)

proc writeItem(nsIndex: uint8, datatype: uint8, key: string, data: pointer, length: uint32, chunkIndex: uint8 = 0xff): esp_err_t =
  let span = if length <= 8: 1.uint8 else: 1.uint8 + ((length - 8 + 31) div 32).uint8
  
  var (pageIdx, maxSeq) = findActivePage()
  if pageIdx == -1: (pageIdx = 0; discard initializePage(pageIdx, maxSeq + 1))
  
  var pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
  var header: PageHeader; discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32)
  if header.state == PS_UNINITIALIZED: (discard initializePage(pageIdx, maxSeq + 1); discard spi_flash_read(pageAddr, addr header, sizeof(header).uint32))

  var entryTable: array[32, uint8]; discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
  var targetEntryIdx = findConsecutiveEntries(entryTable, span.int)
  
  if targetEntryIdx == -1:
    discard markPageFull(pageIdx)
    let nextIdx = (pageIdx + 1) mod NUM_PAGES.int
    let nextAddr = NVS_PARTITION_OFFSET + (nextIdx.uint32 * PAGE_SIZE)
    var nextHeader: PageHeader; discard spi_flash_read(nextAddr, addr nextHeader, sizeof(nextHeader).uint32)
    
    if nextHeader.state == PS_UNINITIALIZED:
      pageIdx = nextIdx
      discard initializePage(pageIdx, maxSeq + 1)
    else:
      pageIdx = nextIdx
      discard compactPage(nextIdx, (nextIdx + 1) mod NUM_PAGES.int, maxSeq + 1)
      let (newIdx, newSeq) = findActivePage()
      pageIdx = newIdx; maxSeq = newSeq

    pageAddr = NVS_PARTITION_OFFSET + (pageIdx.uint32 * PAGE_SIZE)
    discard spi_flash_read(pageAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
    targetEntryIdx = findConsecutiveEntries(entryTable, span.int)
    if targetEntryIdx == -1: return ESP_ERR_NVS_NO_FREE_PAGES

  var item: Item
  item.nsIndex = nsIndex; item.datatype = datatype; item.span = span; item.chunkIndex = chunkIndex
  for i in 0..<min(key.len, 15): item.key[i] = key[i]
  item.key[min(key.len, 15)] = '\0'
  
  let firstChunkLen = min(8.uint32, length)
  if data != nil and firstChunkLen > 0: copyMem(addr item.data[0], data, firstChunkLen)
  item.crc32 = calculateCrc32(item)
  
  let itemAddr = pageAddr + ENTRY_DATA_OFFSET + (targetEntryIdx.uint32 * ENTRY_SIZE)
  discard spi_flash_write(itemAddr, addr item, sizeof(item).uint32)
  
  if span > 1 and data != nil:
    let remainingData = cast[pointer](cast[uint32](data) + 8)
    let remainingLen = length - 8
    discard spi_flash_write(itemAddr + 32, remainingData, remainingLen)
  
  for i in 0..<span.int: setEntryState(entryTable, targetEntryIdx + i, ES_WRITTEN)
  let startWord = targetEntryIdx div 4; let endWord = (targetEntryIdx + span.int - 1) div 4
  for w in startWord..endWord:
    let wordAddr = pageAddr + ENTRY_TABLE_OFFSET + (w.uint32 * 4)
    let wordData = cast[ptr array[8, uint32]](addr entryTable)[w]
    discard spi_flash_write(wordAddr, addr wordData, 4)
  return ESP_OK

proc compactPage(srcIdx: int, destIdx: int, nextSeq: uint32): esp_err_t =
  let srcAddr = NVS_PARTITION_OFFSET + (srcIdx.uint32 * PAGE_SIZE)
  discard initializePage(destIdx, nextSeq)
  
  var entryTable: array[32, uint8]
  discard spi_flash_read(srcAddr + ENTRY_TABLE_OFFSET, addr entryTable, 32)
  
  for i in 0..<ENTRIES_PER_PAGE:
    if getEntryState(entryTable, i) == ES_WRITTEN:
      var item: Item
      let itemAddr = srcAddr + ENTRY_DATA_OFFSET + (i.uint32 * ENTRY_SIZE)
      discard spi_flash_read(itemAddr, addr item, sizeof(item).uint32)
      
      if item.span == 1:
        discard writeItem(item.nsIndex, item.datatype, $cast[cstring](addr item.key[0]), addr item.data[0], 8, item.chunkIndex)
      else:
        let totalLen = 8.uint32 + (item.span.uint32 - 1) * 32
        var buf = newSeq[uint8](totalLen)
        copyMem(addr buf[0], addr item.data[0], 8)
        discard spi_flash_read(itemAddr + 32, addr buf[8], totalLen - 8)
        discard writeItem(item.nsIndex, item.datatype, $cast[cstring](addr item.key[0]), addr buf[0], totalLen, item.chunkIndex)
        
  let wordAddr = srcAddr
  var uninit = PS_UNINITIALIZED.uint32
  discard spi_flash_write(wordAddr, addr uninit, 4)
  return ESP_OK

proc nvs_flash_init*(): esp_err_t {.exportc.} =
  var (pageIdx, _) = findActivePage()
  if pageIdx == -1: return initializePage(0, 1)
  return ESP_OK

proc nvs_flash_deinit*(): esp_err_t {.exportc.} = ESP_OK

proc nvs_open*(name: cstring, mode: int32, handle: ptr nvs_handle_t): esp_err_t {.exportc.} =
  let nameStr = $name
  if nameStr == "phy": (handle[] = 0x1234; return ESP_OK)
  let (res, item, _, _) = findItem(0, T_U8.uint8, nameStr)
  if res == ESP_OK: (handle[] = item.data[0].uint32; return ESP_OK)
  var newId: uint8 = 10; return (if writeItem(0, T_U8.uint8, nameStr, addr newId, 1) == ESP_OK: (handle[] = newId.uint32; ESP_OK) else: 0x1101)

proc nvs_get_u8*(handle: nvs_handle_t, key: cstring, out_value: ptr uint8): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U8.uint8, $key)
  if res == ESP_OK: (out_value[] = item.data[0]; return ESP_OK)
  return res

proc nvs_set_u8*(handle: nvs_handle_t, key: cstring, value: uint8): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U8.uint8, $key)
  var v = value; return writeItem(nsIndex, T_U8.uint8, $key, addr v, 1)

proc nvs_get_i8*(handle: nvs_handle_t, key: cstring, out_value: ptr int8): esp_err_t {.exportc.} =
  return nvs_get_u8(handle, key, cast[ptr uint8](out_value))

proc nvs_set_i8*(handle: nvs_handle_t, key: cstring, value: int8): esp_err_t {.exportc.} =
  var v = value; return nvs_set_u8(handle, key, cast[uint8](v))

proc nvs_get_u16*(handle: nvs_handle_t, key: cstring, out_value: ptr uint16): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U16.uint8, $key)
  if res == ESP_OK: (copyMem(out_value, addr item.data[0], 2); return ESP_OK)
  return res

proc nvs_set_u16*(handle: nvs_handle_t, key: cstring, value: uint16): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U16.uint8, $key)
  var v = value; return writeItem(nsIndex, T_U16.uint8, $key, addr v, 2)

proc nvs_get_i16*(handle: nvs_handle_t, key: cstring, out_value: ptr int16): esp_err_t {.exportc.} =
  return nvs_get_u16(handle, key, cast[ptr uint16](out_value))

proc nvs_set_i16*(handle: nvs_handle_t, key: cstring, value: int16): esp_err_t {.exportc.} =
  var v = value; return nvs_set_u16(handle, key, cast[uint16](v))

proc nvs_get_u32*(handle: nvs_handle_t, key: cstring, out_value: ptr uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U32.uint8, $key)
  if res == ESP_OK: (copyMem(out_value, addr item.data[0], 4); return ESP_OK)
  return res

proc nvs_set_u32*(handle: nvs_handle_t, key: cstring, value: uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U32.uint8, $key)
  var v = value; return writeItem(nsIndex, T_U32.uint8, $key, addr v, 4)

proc nvs_get_i32*(handle: nvs_handle_t, key: cstring, out_value: ptr int32): esp_err_t {.exportc.} =
  return nvs_get_u32(handle, key, cast[ptr uint32](out_value))

proc nvs_set_i32*(handle: nvs_handle_t, key: cstring, value: int32): esp_err_t {.exportc.} =
  var v = value; return nvs_set_u32(handle, key, cast[uint32](v))

proc nvs_get_u64*(handle: nvs_handle_t, key: cstring, out_value: ptr uint64): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, _, _) = findItem(nsIndex, T_U64.uint8, $key)
  if res == ESP_OK: (copyMem(out_value, addr item.data[0], 8); return ESP_OK)
  return res

proc nvs_set_u64*(handle: nvs_handle_t, key: cstring, value: uint64): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_U64.uint8, $key)
  var v = value; return writeItem(nsIndex, T_U64.uint8, $key, addr v, 8)

proc nvs_get_i64*(handle: nvs_handle_t, key: cstring, out_value: ptr int64): esp_err_t {.exportc.} =
  return nvs_get_u64(handle, key, cast[ptr uint64](out_value))

proc nvs_set_i64*(handle: nvs_handle_t, key: cstring, value: int64): esp_err_t {.exportc.} =
  var v = value; return nvs_set_u64(handle, key, cast[uint64](v))

proc nvs_flash_erase*(): esp_err_t {.exportc.} =
  for i in 0..<NUM_PAGES:
    discard spi_flash_erase_sector(NVS_PARTITION_OFFSET div PAGE_SIZE + i.uint32)
  return ESP_OK

proc nvs_get_str*(handle: nvs_handle_t, key: cstring, out_value: cstring, length: ptr uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, pageAddr, entryIdx) = findItem(nsIndex, T_SZ.uint8, $key)
  if res != ESP_OK: return res
  
  let totalCap = 8.uint32 + (item.span.uint32 - 1) * 32
  if out_value == nil: (length[] = totalCap; return ESP_OK)
  
  let copyLen = min(totalCap, length[])
  let itemAddr = pageAddr + ENTRY_DATA_OFFSET + (entryIdx.uint32 * ENTRY_SIZE)
  
  copyMem(out_value, addr item.data[0], min(8.uint32, copyLen))
  if copyLen > 8:
    discard spi_flash_read(itemAddr + 32, cast[pointer](cast[uint32](out_value) + 8), copyLen - 8)
  
  var actualLen: uint32 = 0
  let p = cast[ptr array[1024, char]](out_value)
  for i in 0..<copyLen.int: (if p[i] == '\0': (actualLen = i.uint32 + 1; break))
  if actualLen == 0: actualLen = copyLen
  length[] = actualLen
  return ESP_OK

proc nvs_set_str*(handle: nvs_handle_t, key: cstring, value: cstring): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_SZ.uint8, $key)
  let valStr = $value
  return writeItem(nsIndex, T_SZ.uint8, $key, cast[pointer](value), (valStr.len + 1).uint32)

proc nvs_get_blob*(handle: nvs_handle_t, key: cstring, out_value: pointer, length: ptr uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  let (res, item, pageAddr, entryIdx) = findItem(nsIndex, T_BLOB.uint8, $key)
  if res != ESP_OK: return res
  
  let totalCap = 8.uint32 + (item.span.uint32 - 1) * 32
  if out_value == nil: (length[] = totalCap; return ESP_OK)
  
  let copyLen = min(totalCap, length[])
  let itemAddr = pageAddr + ENTRY_DATA_OFFSET + (entryIdx.uint32 * ENTRY_SIZE)
  copyMem(out_value, addr item.data[0], min(8.uint32, copyLen))
  if copyLen > 8: discard spi_flash_read(itemAddr + 32, cast[pointer](cast[uint32](out_value) + 8), copyLen - 8)
  length[] = copyLen; return ESP_OK

proc nvs_set_blob*(handle: nvs_handle_t, key: cstring, value: pointer, length: uint32): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_BLOB.uint8, $key)
  return writeItem(nsIndex, T_BLOB.uint8, $key, value, length)

proc nvs_close*(handle: nvs_handle_t) {.exportc.} = discard
proc nvs_commit*(handle: nvs_handle_t): esp_err_t {.exportc.} = ESP_OK

proc nvs_erase_key*(handle: nvs_handle_t, key: cstring): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  eraseOldItem(nsIndex, T_ANY.uint8, $key); return ESP_OK

proc nvs_erase_all*(handle: nvs_handle_t): esp_err_t {.exportc.} =
  let nsIndex = if handle == 0x1234: 0.uint8 else: handle.uint8
  for pageIdx in 0..<NUM_PAGES:
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
