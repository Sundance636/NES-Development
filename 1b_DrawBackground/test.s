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

  ldx #%00000000 ;set address for nametable and sprites
  stx $2000 ;PPU control register

  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address
  sta $2006

  lda #$1A ; green background color
  sta $2007 ;writes to the address (3F00) in vram with PPU's help

  lda #%10000000 ; zero into A register
  sta $2000 ;NMI enable
  lda #$00

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

  ldx #$2d  ;grey

  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$01 ; lower byte of the address (bkg palette 0, index 0)
  sta $2006

  stx $2007 ;writes to bkg palette 0

  ldx #$1D ;black
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$02 ; lower byte of the address (sprite palette 0, index 1)
  sta $2006

  stx $2007 ;writes to bkg palette 0

  ldx #$11 ;blue
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$03 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006

 stx $2007 ;writes to bkg palette 0


  ldx #$23  ;light pink

  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$05 ; lower byte of the address (bkg palette 0, index 0)
  sta $2006

  stx $2007 ;writes to bkg palette 0

  ldx #$16 ;orange
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$06 ; lower byte of the address (sprite palette 0, index 1)
  sta $2006

  stx $2007 ;writes to bkg palette 0

  ldx #$20 ;white
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$07 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006

  stx $2007 ;writes to bkg palette 0

  ldx #00
  ldy #00


  lda #$00 ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$20 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006

;patterntable:
;  lda bordercorner, x ;tile's pattern data
;
;  ;sta $2007 ;to patterntable

;  inx

;  cpx #$0F
;  bcc patterntable

;  ldx #$00
;  ldy #$00

nameTables:;name table 0 starts at $2000 in ppu
  ldx #00 ;load the tile data into accumulator
  lda #$20 ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006

  stx $2007

  ldx #0 ;tile 2 to go to the nametable
  stx $2007

  iny ;incrementtile

  cpy #$0F ;compare x with F (15)
  bcc nameTables


  lda #$23 ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$CF ; lower byte of the address
  sta $2006

  lda #1 ; bkg palette to select
  sta $2007 ;send to ppu

  ldx #00
  ldy #00

  lda #$20 ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006
  lda #04


;vblankcheck3: ; vblank check to wait for PPU to start up
 ; bit $2002 ;tests vblank bit, specifically bit 7
 ; bpl vblankcheck3 ;loops until the vblank bit is set

  lda #04

  ldx #%00000000 ;enabling rendering during vblank
  stx $2001 ;PPU mask register
  ldx #$00

background_sky:
  
  ;ldx #00 ;load the tile data into accumulator

  sta $2007
  iny
  cpy #$20
  

  ;lda #%00000000 ; zero into A register
 ; sta $2000 ;NMI disable
 ; lda #04
  bcc background_sky



  ldy #$00
  inx
  clc
  cpx #$17


  bcc background_sky

  lda #$03
  clc

drawground:
  sta $2007
  iny
  cpy #$20
  

  ;lda #%00000000 ; zero into A register
 ; sta $2000 ;NMI disable
 ; lda #04
  bcc drawground

  lda #$06
  ldy #$00
  ldx #$00

drawgrass:
  sta $2007
  iny
  cpy #$20
  

  ;lda #%00000000 ; zero into A register
 ; sta $2000 ;NMI disable
 ; lda #04
  bcc drawgrass



  ldy #$00
  inx
  clc
  cpx #$06


  bcc drawgrass


  ldx #%00011110 ;enabling rendering during vblank
  stx $2001 ;PPU mask register
  ldx #$00
  ldx #007




attributetable: 
  ;sta $2007 ;for selecting palattes

  inx

  cpx #$0F
  bcc attributetable

loop:
  jmp loop

tile2:
.byte %11111111;upper bit
.byte %11000011
.byte %10100101
.byte %10011001
.byte %10011001
.byte %10000001
.byte %10000001
.byte %10000001

.byte %11111111;lower bit
.byte %10111101
.byte %11011011
.byte %11100111
.byte %10000001
.byte %10000001
.byte %10000001
.byte %10000001

.SEGMENT "CHARS"
tile:
.byte %11111111;upper bit
.byte %11000011
.byte %10100101
.byte %10011001
.byte %10011001
.byte %10000001
.byte %10000001
.byte %10000001

.byte %11111111;lower bit
.byte %10111101
.byte %11011011
.byte %11100111
.byte %10000001
.byte %10000001
.byte %10000001
.byte %10000001

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

bordercorner:
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %10000000
  .byte %00000000

grass:
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
sky:
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

circle:
  .byte %11111111
  .byte %11000011
  .byte %10111101
  .byte %01111110
  .byte %01111110
  .byte %10111101
  .byte %11000011
  .byte %11111111

  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
