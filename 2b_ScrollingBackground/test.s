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
  .addr interrupts ;nmi ;$FFFA-$FFFB = NMI vector (goes to "nmi" when interrupt happens)
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
  bit $2002 ;tests vblank bit


nmi:
  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003 ;address of OAM to access, for sprites


vblankcheck1: ;first vblank check to wait for PPU to start up
  bit $2002 ;tests vblank bit, specifically bit 7
  bpl vblankcheck1 ;loops until the vblank bit is set

  lda #$00
  
memclear: ; initializes ram and wipes it clean during vblank

  sta $100, x ;x is the offset off the memory address
  sta $200, x
  sta $300, x 
  sta $400, x
  sta $500, x
  sta $600, x
  sta $700, x

  inx ;increment offset
  bne memclear ;loops until x is zero again clearing this block of memory

  lda #$00
  jsr vblankwait ;the seccond vblank wait

  lda #$00

  jsr paletteInit ;fill as all background and sprite palettes

  ldx #%00011110 ;enabling rendering
  stx $2001 ;PPU mask register

  ldx #%10000000 ;set address for nametable and sprites in PPU
  stx $2000 ;PPU control register
  ldx #$00 ;clear register

  lda #%10000000 ; zero into Accumulator
  sta $2000 ;NMI enable
  lda #$00 ;clears accumulator

  jsr nameTable_draw ;draws the initial background
  jsr enableRendering

  sta $0200;initialze the memory for camera positions
  sta $0201 ;cameras y position

  lda #$00
  ldx #$00


main:
  jsr ScanInput
  jsr Controller

  jmp main


;FUNCTIONS/DATA BELOW HERE.

interrupts: ;caled when an interrupt happens

rti

delayLoop:
  inx
  cpx #$FF
  bcc delayLoop
  rts

ScreenScroll:;address $0200 stores camera x and $0201 camera y
  ldx $0200 ;load the camera position
  inx ;increment the camera position
  stx $0200 ;store the new number 

  bit $2002

  stx $2005 ;writes to X position
  ldx #$00
  stx $2005 ;Writes to Y position


  rts

ScreenScrollL:;address $0200 stores camera x and $0201 camera y
  ldx $0200 ;load the camera position
  dex ;decrement the camera position
  stx $0200 ;store the new number 

  bit $2002

  stx $2005 ;writes to X position
  ldx #$00
  stx $2005 ;Writes to Y position


  rts

ScanInput:
  ldx #$01 ;1 to enable controller polling
  ;stx $0215 
  stx $4016 ; write 1 to this register to signal controller to poll
  
  ldx #$00 ;clear register
  stx $4016 ; write 0 to capture input and stop scaning


  ;ldx $4016
  ;stx $0215
  rts



Controller: ;process controller inputs

  ldx $4016 ;read controller state

  stx $0210 ;store the controller's state at memory address $0210
  lda $0210
  sta $0220, y ;store all buttons' state in memory

  iny ;keeps track of reads

  cpy #$06 ;get to the sixth read(left direction)
  bcc Controller
  ldy #$00

  ldx #$00

  jsr delayLoop ;to slow down the scroll speed
  jsr delayLoop
  jsr delayLoop
  jsr delayLoop

  jsr CheckLeft
  jsr CheckRight

  rts

CheckLeft:
  ldx $4016 ;read controller state (7TH)
  stx $0210 ;store the controller's state at memory address $0210

  cpx #$41
  bcs Leftpress
  rts

Leftpress:
  stx $0211
  jsr ScreenScrollL

rts

CheckRight:
  ldx $4016 ;read controller state
  stx $0210 ;store the controller's state at memory address $0210

  cpx #$41
  bcs Rightpress
  
  rts

Rightpress:
  stx $0212
  jsr ScreenScroll
rts

Return:
  rts

enableRendering:
  ldx #%00011110 ;enabling rendering
  stx $2001 ;PPU mask register
  rts

nameTable_draw:
  lda #$20 ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006

  lda#04

  ldx #%00000000 ;disable rendering temporarily to draw
  stx $2001 ;PPU mask register
  ldx #$00

draw_Background_sky:
  sta $2007
  iny
  cpy #$20
  bcc draw_Background_sky

  ldy #$00
  inx
  clc
  cpx #$17

  bcc draw_Background_sky

  lda #$20 ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address (sprite palette 0, index 2)
  sta $2006
  ldx #$00

skyCircles:
  lda #$04
  sta $2007
  iny
  cpy #$16
  bcc skyCircles

  lda #$05
  sta $2007
  ldy #$00
  inx
  clc
  cpx #$20

  bcc skyCircles

  lda #$03
  clc

drawground:
  sta $2007
  iny
  cpy #$20

  bcc drawground

  lda #$06
  ldy #$00
  ldx #$00

drawGrass:
  sta $2007
  iny
  cpy #$20

  bcc drawGrass

  ldy #$00
  inx
  clc
  cpx #$06

  bcc drawGrass
  rts

vblankwait:
  bit $2002
  bpl vblankwait
  rts

paletteInit:
  lda #$3F ;upperbyte of the address
  sta $2006 ;to the PPU data register
  lda #$00 ; lower byte of the address (for palettes)
  sta $2006
  ldx #$00
  
paletteloop:
  lda palettes, x
  sta $2007
  
  inx

  cpx #$20
  bcc paletteloop
  rts

palettes:
  .byte $1A,$2D,$1D,$11 ;BKG palette 0: Green, Grey, Black, Blue
  .byte $00,$23,$16,$20 ;BKG palette 1: null, Pink, Orange, White
  .byte $00,$0A,$1D,$11 ;BKG palette 2: null, Dark Green, Black, Blue
  .byte $00,$28,$0C,$1D ;BKG palette 3: null, Gold, Dark Blue, Black

  .byte $1A,$14,$1D,$38 ;Sprite palette 0: Green, Purple, Black, Yellow
  .byte $00,$06,$26,$17 ;Sprite palette 1: null, Red, Orange, Brown
  .byte $00,$01,$21,$20 ;Sprite palette 2: null, Dark Blue,light Blue,White
  .byte $00,$2A,$19,$3A ;Sprite palette 3: null, light Green, Green, pale Green

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
