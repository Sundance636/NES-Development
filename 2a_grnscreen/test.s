.segment "HEADER" ; header section for the ines file format
  .byte $4E, $45, $53, $1A ;("NES" followed by MS-DOS end-of-file)
  .byte 2         ; 1 or 2 for NROM-128 or NROM-256 respectively
  .byte 1         ; 8 KiB CHR ROM
  .byte $00       ; Mapper 0; $00 or $01 for horizontal or vertical mirroring respectively
  .byte $00       ; Mapper 0; NES 2.0
  .byte $00       ; No submapper
  .byte $00       ; PRG ROM not 4 MiB or larger
  .byte $00       ; No PRG RAM
  .byte $00       ; No CHR RAM
  .byte $00       ; 0 or 1 for NTSC or PAL respectively
  .byte $00       ; No special PPU
  .byte $00       ; unused flags set off
  .byte $00       ; unused flags set off

.segment "VECTORS"
  .addr nmi
  .addr reset
.segment "STARTUP"

.segment "CHARS"

.segment "CODE"

reset: ;startup/reset routine
  sei ;disable irq
  
  lda #$00 ; zero into A register

  sta $2000 ;NMI disable
  sta $2001 ;rendering disable

  ldx #$FF ; FF into x register
  txs ;initialze stack pointer to 00FF


  cld ; clears the decimal bit in SR (status register)

  lda #0
  ldx #0

  sta $4010 ;disables the DMC IRQs
  bit $2002

nmi:
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003 ;address of OAM to access, object

vblankcheck1: ;first vblank check to wait for PPU to start up
  bit $2002 ;tests vblank bit
  bpl vblankcheck1 ;loops until the vblank bit is clear

memclear: ; initializes ram and wipes it clean

  sta $100, x ;x is the offset off the memory address
  sta $200, x
  sta $300, x
  sta $400, x
  sta $500, x
  sta $600, x
  sta $700, x
  inx ;increment offset
  bne memclear ;loops until x is zero again

vblankcheck2: ; second vblank check for PPU
  bit $2002
  
  ldx #%00011110 ;enabling rendering during vblank
  stx $2001

  ldx #%01010000 ;set address for nametable and sprites
  stx $2000

  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #00 ; lower byte of the address
  sta $2006

  lda #$1A ; green bacground color

  sta $2007 ;writes to the address (3F00) in vram with PPU's help
  bit $2002 ;vblank clear

  bpl vblankcheck2

  
  ;ldx #$14  ;purple
palette:
  ;sta $3F00 ; background color
  ;stx $3F02 ;palette 1


main:

  loop:
    jmp loop