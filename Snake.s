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


Titlescreen:
  jsr ScanInput
  jsr Controller

  inc $02A0 ; address to store game seed

  ldy $0223 ;address for start button
  cpy #$41 ;if start is pressed continue to main game
  ldy #$00
  bcc Titlescreen ; keep looping incrementing seed until start is pressed

  jsr spriteloop ;initializes sprite data


main: ;main game loop
  jsr PelletCollision
  jsr spawnPellet
  jsr ScanInput
  jsr Controller
  
  jsr move
  jsr delayLoop

  jsr move
    jsr delayLoop

  jsr move
    jsr delayLoop
  jsr move
    jsr delayLoop
 
  jsr move
    jsr delayLoop

  jsr move
    jsr delayLoop

  jsr move
    jsr delayLoop

  jsr move
  jsr delayLoop
  ldy #$00

     

  jmp main



;FUNCTIONS/DATA BELOW HERE.

interrupts: ;caled when an interrupt happens

rti

move:; change 2 to 4
    ldx $0244 ;up press
    cpx #$41
    bcs moveUP
    
    ldx $0245 ;down press
    cpx #$41
    bcs moveDOWN

    ldx $0246 ;left press
    cpx #$41
    bcs moveLEFT

    ldx $0247 ;right press
    cpx #$41
    bcs moveRIGHT

    rts

moveUP:
    ldx $0300 ;position
    cpx #$08 ;screen  bound

    beq Return ;prevent going off screen bounds

    ldx $0234 ; sprite flip memory address
    cpx #$01 ; check if already flipped

    lda #$01 ; func argument
    ldy #%10000000 ; func argment 2
    bcs verticalFlip

    lda $0301
    cpx #01 ;check if right sprite

    lda #$01 ;func arg
    bcc verticalFlip

    dec $0300

  lda #$03 ; when writing to PPU OAM 0200 to 02FF
  sta $4014 ; write sprite data to PPU OAM
    rts


moveDOWN:
    ldx $0300 ;position in memory
    cpx #$D8 ;screen bound

    bcs Return ;prevent going off screen bounds

    ldx $0234 ; flip memory address
    cpx #$01 ; check if already flipped

    lda #$00 ;func argument
    ldy #%00000000 ; func argument 2
    bcs verticalFlip

    lda $0301 ;load the tile's index
    cpx #01 ;check if right sprite is loaded

    lda #$00 ;function argument
    bcc verticalFlip

    inc $0300

  lda #$03 ; when writing t ldx $0224 ;
  sta $4014 ; write sprite data to PPU OAM
    
    rts

Return:
  rts

moveLEFT:
    ldx $0303 ;load position
    cpx #$00 ;screen bound

    beq Return ;prevent going off screen bounds

    lda #$01 ; func argument (flag  for if flipped)
    ldy #%01000000 ;func argument (bits to send to PPU to flip)

    ldx $0235 ; load flip memory for x
    cpx #$01 ; check if already flipped

    bcc horizontalflip ; dont branch if already flipped

    ldx $0301 ;load tile index
    cpx #$02 ;check for sprite swap

    bcc horizontalflip ; branch if using the wrong tile

    ldy #$00 ;clear register if unused in current call
    dec $0303
  lda #$03 ; when writing to PPU OAM 0200 to 02FF
  sta $4014 ; write sprite data to PPU OAM

    rts


moveRIGHT:
    ldx $0303
    cpx #$F8

    bcs Return ;prevent going off screen bounds

    ldx $0235 ; flip memory for x
    cpx #$01 ; check if already flipped

    lda #$00 ;argument for func
    ldy #%00000000 ;func arument
    bcs horizontalflip

    ldx $0301
    cpx #$02 ;check for sprite swap

    bcc horizontalflip

    inc $0303
  lda #$03 ; when writing to PPU OAM 0200 to 02FF
  sta $4014 ; write sprite data to PPU OAM

    rts

verticalFlip:

  ;lda #$01
  sta $0234 ;marking as flipped

  ;lda #%10000000
  sty $0302 ;flip in ppu
  ldx #$01 ;selects tile to use
  stx $0301 ;stores selection

  jsr incdecCheck2 ;check to increment or decrement
  ;dec $0300

  ldy #$00
  lda #$03 ; when writing to PPU OAM 0200 to 02FF
  sta $4014 ; write sprite data to PPU OAM

  rts

horizontalflip:

  ;lda #$00
  sta $0235 ;mark as not flipped/ is flipped

  ;lda #%00000000
  sty $0302 ;flip oam data
  ldx #$02 ;load tile index to swap
  stx $0301 ;tile byte address

  jsr incdecCheck ;increment/decrement
  ;inc $0303

  ;ldy #$00
  lda #$03 ; when writing to PPU OAM 0200 to 02FF
  sta $4014 ; write sprite data to PPU OAM

  rts

incdecCheck:
  ldy #$00
  cmp #$01 ;check whether flipped or not
  bcs decrementhori ;decrement if left
  inc $0303 ;increment if right
  rts

decrementhori:
  dec $0303 ;decrement if pressed left
  rts

incdecCheck2:
  ldy #$00
  cmp #$01 ;whether it flipped or not
  bcs decrementvert
  inc $0300
  rts

decrementvert:
  dec $0300
  rts

spriteloop:
  lda SnakeHeadOAM, x
  sta $0300, x ;memory for sprite oam
  inx
  cpx #$04
  bcc spriteloop

  lda #$03 ; when writing to PPU OAM 0200 to 02FF
  sta $4014 ; write sprite data to PPU OAM

  ldx #00
  lda #$00

  rts

nameTable_draw:;FUNCTIONS/DATA BELOW HERE.
    rts

delayLoop: ;used to stall
  inx
  cpx #$FF
  bcc delayLoop
  iny
  cpy #$08
  bcc delayLoop
  rts
  

ScanInput:
  ldx #$01 ;1 to enable controller polling
  ;stx $0215 
  stx $4016 ; write 1 to this register to signal controller to poll
  
  ldx #$00 ;clear register
  stx $4016 ; write 0 to capture input and stop scaning

  rts

Controller: ;process controller inputs

  lda $4016 ;read controller state

  ;stx $0210 ;store the controller's state at memory address $0210
  ;lda $0210
  sta $0220, y ;store all buttons' state in memory
  jsr storePress ;stores the most recent d pad direction

  iny ;keeps track of reads

  cpy #$08 ;get to the sixth read(left direction)
  bcc Controller

  ldy #$00
  lda #$00
  ldx #$00

  rts

loopInit:
  ldx #$00
  cpx #$00

incrementLoop:
  inc $0300
  inx
  cpx #$08
  bcc incrementLoop

  rts

storePress:
  tax ;transfers the accumulator to x
  cpx #$41 ;check if there was a button pressed
  bcs storePress2 ;branches if pressed

  ldx #$00

  rts

storePress2:
  ldx #$00

  stx $0240
  stx $0241
  stx $0242
  stx $0243
  stx $0244
  stx $0245
  stx $0246
  stx $0247

  sta $0240, y
  rts

Return2: ;second return function to branch to
  rts

spawnPellet:
  lda #$00 ;00 means no pellet
  cmp $02B0 ;stores info on whether a pellet is currently spawned
  bcc Return2 ;skip spwan routine if there is already a pellet

  jsr rng ;first excecution of function always returns zero for some reason
  jsr screenboundCheck ;gens random number and checks bounds

  lsr $0307 ;shift three times and back to force a multiple of 8
  lsr $0307
  lsr $0307
  clc ;clears carry bit just in case to not interfere with pellet spwan
  rol $0307
  rol $0307
  rol $0307

  lsr $0304 ;shift three times and back to force a multiple of 8
  lsr $0304
  lsr $0304
  clc
  rol $0304
  rol $0304
  rol $0304

  lda #$06
  sta $0305 
  lda #%00000001
  sta $0306 ;pallete index (two lowest bits)

  lda #$03 ; when writing to PPU OAM 0300 to 03FF
  sta $4014 ; write sprite data to PPU OAM

  lda #$01
  sta $02B0 ; update flag for pellet
  lda #$00

  rts

rng:
  lda $02A0+1
	tay ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr ; shift to consume zeroes on left...
	lsr
	lsr
	sta $02A0+1 ; now recreate the remaining bits in reverse order... %111
	lsr
	eor $02A0+1
	lsr
	eor $02A0+1
	eor $02A0+0 ; recombine with original low byte
	sta $02A0+1
	; compute seed+0 ($39 = %111001)
	tya ; original high byte
	sta $02A0+0
	asl
	eor $02A0+0
	asl
	eor $02A0+0
	asl
	asl
	asl
	eor $02A0+0
	sta $02A0+0
	rts

screenboundCheck: ;checks to make sure spawned pellet is within screen bounds
  jsr rng
  sta $0307 ;x coordinate of pellet spwan location
  cmp #$F9 ; check if x is too high
  bcs screenboundCheck ;loop until vaid number

  jsr rng
  sta $0304 ;y coordinate of pellet spawn location
  cmp #$E0 ; check if y is too high
  bcs screenboundCheck ;loop until vaid number
  cmp #$08 ; check if y is too low
  bcc screenboundCheck ;loop until vaid number

  rts

PelletCollision:
  lda $0303 ;head x position
  sta $02C0 
  lda $0300 ;head y position
  sta $02C1

  lda $0307 ;pellet x position
  sta $02C2 
  lda $0304 ;pellet y position
  sta $02C3

  cmp $0300 ; compare y positions
  beq PelletCollision2

  rts

PelletCollision2:
  lda $0307
  cmp $0303 ; compare x positions

  beq HitDetected
  rts

HitDetected:
  inc $02D0 ;memory address to track points
  lda #$00
  sta $02B0 ;mark pellet as despawned

  rts
enableRendering:
  ldx #%00011110 ;enabling rendering
  stx $2001 ;PPU mask register
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

SnakeHeadOAM:
  .byte $20 ;initialize starting ;y position to a multiple of 8
  .byte $01
  .byte %00000000
  .byte $10

palettes:
  .byte $1A,$2D,$1D,$11 ;BKG palette 0: Green, Grey, Black, Blue
  .byte $00,$23,$16,$20 ;BKG palette 1: null, Pink, Orange, White
  .byte $00,$0A,$1D,$11 ;BKG palette 2: null, Dark Green, Black, Blue
  .byte $00,$28,$0C,$1D ;BKG palette 3: null, Gold, Dark Blue, Black

  .byte $1A,$0A,$1D,$16 ;Sprite palette 0: Green, Dark Green, Black, Red
  .byte $00,$06,$26,$17 ;Sprite palette 1: null, Red, Orange, Brown
  .byte $00,$01,$21,$20 ;Sprite palette 2: null, Dark Blue,light Blue,White
  .byte $00,$2A,$19,$3A ;Sprite palette 3: null, light Green, Green, pale Green

.SEGMENT "CHARS" ;tile/pattern table data

Background:
  .byte %00000000;lower bit
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000000;upper bit
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

SnakeHead:
  .byte %00111100;lower bit
  .byte %00111100
  .byte %01111110
  .byte %01011010
  .byte %01011010
  .byte %01111110
  .byte %00111100
  .byte %00000000

  .byte %01000010;upper bit
  .byte %01000010
  .byte %10000001
  .byte %10100101
  .byte %10100101
  .byte %10000001
  .byte %01011010
  .byte %00111100

SnakeHeadHor:
  .byte %00000000;lower bit
  .byte %00111100
  .byte %11100110
  .byte %11111110
  .byte %11111110
  .byte %11100110
  .byte %00111100
  .byte %00000000

  .byte %00111100;upper bit
  .byte %11000010
  .byte %00011001
  .byte %00000011
  .byte %00000011
  .byte %00011001
  .byte %11000010
  .byte %00111100

SnakeBody:
  .byte %00111100 ;low
  .byte %00111100
  .byte %00111100
  .byte %00111100
  .byte %00111100
  .byte %00111100
  .byte %00111100
  .byte %00111100

  .byte %01000010 ;upper
  .byte %01000010
  .byte %01000010
  .byte %01000010
  .byte %01000010
  .byte %01000010
  .byte %01000010
  .byte %01000010

SnakeBend:
  .byte %00111100 ;low
  .byte %00111110
  .byte %00111111
  .byte %00111111
  .byte %00011111
  .byte %00001111
  .byte %00000000
  .byte %00000000

  .byte %01000010 ;upper
  .byte %01000001
  .byte %01000000
  .byte %01000000
  .byte %01100000
  .byte %00110000
  .byte %00011111
  .byte %00000000

SnakeTail:
  .byte %00111100 ;low
  .byte %00111100
  .byte %00111100
  .byte %00111100
  .byte %00011000
  .byte %00011000
  .byte %00000000
  .byte %00000000

  .byte %01000010 ;upper
  .byte %01000010
  .byte %01000010
  .byte %01000010
  .byte %01100110
  .byte %00100100
  .byte %00111100
  .byte %00011000

Pellet:
  .byte %00000000 ;low
  .byte %00011000
  .byte %00111100
  .byte %01111110
  .byte %01111110
  .byte %00111100
  .byte %00011000
  .byte %00000000

  .byte %00000000 ;upper
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
