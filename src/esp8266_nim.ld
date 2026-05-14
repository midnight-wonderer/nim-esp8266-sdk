/* 
 * Simplified Linker Script for Nim Port on ESP8266
 * Derived from ESP8266 RTOS SDK
 */

ENTRY(call_start_cpu);

MEMORY
{
  iram0_0_seg (RX) :                 org = 0x40100000, len = 0xC000
  dram0_0_seg (RW) :                 org = 0x3FFE8000, len = 0x18000
  iram0_2_seg (RX) :                 org = 0x40210000, len = 0xF0000
  rtc_data_seg (RWX) :               org = 0x60001000, len = 0x300
}

PHDRS
{
  iram0_0_phdr PT_LOAD;
  dram0_0_phdr PT_LOAD;
  iram0_2_phdr PT_LOAD;
}

SECTIONS
{
  /* RTC */
  .rtc.data :
  {
    _rtc_data_start = ABSOLUTE(.);
    *(.rtc.data .rtc.data.*)
    _rtc_data_end = ABSOLUTE(.);
  } > rtc_data_seg

  .rtc.bss (NOLOAD) :
  {
    _rtc_bss_start = ABSOLUTE(.);
    *(.rtc.bss .rtc.bss.*)
    _rtc_bss_end = ABSOLUTE(.);
  } > rtc_data_seg

  /* IRAM */
  .iram0.vectors :
  {
    _iram_start = ABSOLUTE(.);
    _init_start = ABSOLUTE(.);
    KEEP(*(.SystemInfoVector.text));
    . = 0x10;
    KEEP(*(.DebugExceptionVector.text));
    . = 0x20;
    KEEP(*(.NMIExceptionVector.text));
    . = 0x30;
    KEEP(*(.KernelExceptionVector.text));
    . = 0x50;
    KEEP(*(.UserExceptionVector.text));
    . = 0x70;
    KEEP(*(.DoubleExceptionVector.text));

    *(.*Vector.literal)
    *(.UserEnter.literal);
    *(.UserEnter.text);
    . = ALIGN (16);
    *(.entry.text)
    *(.init.literal)
    *(.init)
    _init_end = ABSOLUTE(.);
  } > iram0_0_seg : iram0_0_phdr

  .iram0.text :
  {
    _iram_text_start = ABSOLUTE(.);
    *(.iram1 .iram1.*)
    *(.iram0.text .iram0.text.*)
    *(.iram0.literal .iram0.literal.*)
    _iram_text_end = ABSOLUTE(.);
  } > iram0_0_seg : iram0_0_phdr

  .iram0.bss (NOLOAD) :
  {
    . = ALIGN (4);
    _iram_bss_start = ABSOLUTE(.);
    *(.iram.bss .iram.bss.*)
    . = ALIGN (4);
    _iram_bss_end = ABSOLUTE(.);
    _iram_end = ABSOLUTE(.);
  } > iram0_0_seg

  /* DRAM */
  .dram0.data :
  {
    _data_start = ABSOLUTE(.);
    *(.data .data.*)
    *(.sdata .sdata.*)
    *(.gnu.linkonce.d.*)
    *(.gnu.linkonce.s.*)
    _data_end = ABSOLUTE(.);
    . = ALIGN(4);
  } > dram0_0_seg : dram0_0_phdr

  .dram0.bss (NOLOAD) :
  {
    . = ALIGN (8);
    _bss_start = ABSOLUTE(.);
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN (8);
    _bss_end = ABSOLUTE(.);
    _heap_start = ABSOLUTE(.);
  } > dram0_0_seg

  /* FLASH */
  .flash.text :
  {
    _text_start = ABSOLUTE(.);
    *(.irom0.literal .irom0.text .irom.literal .irom.text)
    *(.literal .text .literal.* .text.*)
    *(.stub .gnu.warning .gnu.linkonce.literal.* .gnu.linkonce.t.*)
    _text_end = ABSOLUTE(.);
  } > iram0_2_seg : iram0_2_phdr

  .flash.rodata :
  {
    _rodata_start = ABSOLUTE(.);
    . = ALIGN(4);
    *(.rodata .rodata.*)
    *(.gnu.linkonce.r.*)
    *(.rodata1)
    . = ALIGN(4);
    __init_array_start = ABSOLUTE(.);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    __init_array_end = ABSOLUTE(.);
    __XT_EXCEPTION_TABLE_ = ABSOLUTE(.);
    *(.xt_except_table)
    *(.gcc_except_table .gcc_except_table.*)
    . = ALIGN(4);
    _rodata_end = ABSOLUTE(.);
  } > iram0_2_seg : iram0_2_phdr

  /* Reserve NVS space at 1MB mark */
  _nvs_base = 0x100000;
  _nvs_len  = 0x8000;
  .nvs_reserved _nvs_base (NOLOAD) :
  {
    . = . + _nvs_len;
  }
}
