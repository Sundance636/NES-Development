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

.segment "VECTORS" ;interrupt vectors
  .addr nmi ;$FFFA-$FFFB = NMI vector
  .addr reset ;$FFFC-$FFFD = Reset vector
  ;irqs
.segment "STARTUP"

.segment "CODE"

reset: ;startup/reset routine
  sei ;disable irq(interrupt requests) $FFFE-$FFFF = IRQ/BRK vector
  
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
  stx $2003 ;address of OAM to access, for sprites


vblankcheck1: ;first vblank check to wait for PPU to start up
  bit $2002 ;tests vblank bit, specifically bit 7
  bpl vblankcheck1 ;loops until the vblank bit is set

memclear: ; initializes ram and wipes it clean during vblank

  sta $100, x ;x is the offset off the memory address
  sta $300, x
  sta $400, x
  sta $500, x
  sta $600, x
  sta $700, x

  lda #$FF ;initializes OAM buffer to FF to keep sprites off the screen
  sta $200, x
  lda #$00

  inx ;increment offset
  bne memclear ;loops until x is zero again clearing this block of memory

vblankcheck2: ; second vblank check for PPU
  bit $2002
  bpl vblankcheck2 ;vblank is set again
  
  ldx #%00011110 ;enabling rendering during vblank
  stx $2001 ;PPU mask register

  ldx #%00010000 ;set address for nametable and sprites
  stx $2000 ;PPU control register

  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address
  sta $2006

  lda #$1A ; green background color
  sta $2007 ;writes to the address (3F00) in vram with PPU's help


palette: ;set up sprite palette 0
  ldx #$14  ;purple

  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$11 ; lower byte of the address (sprite palette 0, index 0)
  sta $2006

  stx $2007 ;writes to sprite palette 0

  ldx #$1D ;black
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$12 ; lower byte of the address (sprite palette 0, index 1)
  sta $2006

  stx $2007 ;writes to sprite palette 0

  ldx #$38 ;yellow
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$13 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006

  stx $2007 ;writes to sprite palette 0

  ldx #00

spriteloop:
  lda sqrOAM, x
  sta $0200, x
  inx
  cpx #$04
  bcc spriteloop

  lda #$02 ; when writing to PPU OAM 0200 to 02FF

  sta $4014 ; write sprite data to PPU OAM
  ldx #00

patterntbl:
  lda squareface, x
  sta $0000, x
  inx

  cpx #$0F
  bcc patterntbl


main:
  jsr pollInput

  jmp main

pollInput:
  lda #$01 ;load 1
  sta $4016 ;controller 1

  ;sta $0300 ;address for buttons 

  lda #$00 ;load 0
  sta $4016 ; controller 1 finish poll

  
  ldx #$FF
  jsr readinput
  ldx #$FF
  ;bit $0300 ;button pushed is right

  jsr moves

readinput:
  inx
  lda $4016
  
  lsr a

  rol $0300
  cpx #$07

  bcc readinput
  rts
  
moves:
  clc
  inx
  cpx #$08
  bcs pollInput
  lsr $0300


  bcc moves

  bcs right;if the 7th bit is set

  

right:
  inc $0203 ;sprite x coordinate
  lda #$02 ; when writing to PPU OAM 0200 to 02FF

  sta $4014 ; write sprite data to PPU OAM
  jmp main

sqrOAM:
  .byte $1F
  .byte $00
  .byte %00000000
  .byte $10

.segment "CHARS"

squareface: ;sprites start at $00
  .byte %00000000
  .byte %01111110
  .byte %01011010
  .byte %01111110
  .byte %01111110
  .byte %01111110
  .byte %01111110
  .byte %00000000

  .byte %11111111
  .byte %10000001
  .byte %10100101
  .byte %10000001
  .byte %10100101
  .byte %10111101
  .byte %10000001
  .byte %11111111
