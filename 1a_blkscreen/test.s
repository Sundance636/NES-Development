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
    .addr nmi ; nmi(NON masking interupt) routine
    .addr reset ;actions to perform at startup/when console is reset
    ;.addr 0 ;External interrupt IRQ (unused)
.segment "STARTUP"

.segment "CHARS"
  .byte %11000011	; H (00)
  .byte %11000011
  .byte %11000011
  .byte %11111111
  .byte %11111111
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11111111	; E (01)
  .byte %11111111
  .byte %11000000
  .byte %11111100
  .byte %11111100
  .byte %11000000
  .byte %11111111
  .byte %11111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %11000000	; L (02)
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11111111
  .byte %11111111
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  .byte %01111110	; O (03)
  .byte %11100111
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte %11000011
  .byte %11100111
  .byte %01111110
  .byte $00, $00, $00, $00, $00, $00, $00, $00

.segment "CODE";default code segment

.proc nmi ;.proc is basically like a local function
  bit $2002 ;clears vblank flag in the PPU status register
  lda #0 ;put zero into A register

  ; writing twice to the PPUADDR register ($2006)
  ; (twice becuasse the first
  ; write is the upper byte and the
  ; seccond is the lower byte)

  sta $2006
  sta $2006 

  ldx #$00 	; Set SPR-RAM address to 0
  stx $2003
@loop:	lda hello, x 	; Load the hello message into SPR-RAM
  sta $2004
  inx
  cpx #$1c
  bne @loop
  rti


  rti ;return from interuppt
.endproc

hello:
  .byte $00, $00, $00, $00 	; Why do I need these here?
  .byte $00, $00, $00, $00
  .byte $6c, $00, $00, $6c
  .byte $6c, $01, $00, $76
  .byte $6c, $02, $00, $80
  .byte $6c, $02, $00, $8A
  .byte $6c, $03, $00, $94

.proc ResetPalettes
  bit $2002 ;clear vblank bit in the PPU status register
  lda #%00011110;PPU mask parameters
  sta $2001 ; ppu mask resigter

  lda #$3f ; writing 3F00 to PPUADDR register
  sta $2006
  lda #$00
  sta $2006

  lda #$0F ;value to be written to PPUDATA
  ldx #$20
@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop
  
  rts ;return from subroutine
.endproc

reset:
sei;disables interupts
lda #%01000001;PPU parameters
sta $2000 ; store at address (disables nmi) 

lda #%00000000;00011110;PPU mask parameters
sta $2001 ; ppu mask resigter

ldx #$FF ;load address 0100 hex to x register
txs ;initialize the stack pointer to the start of the cart
inx
cld ; clears the decimal flag

lda #%00000000
sta $4010 ;disables interrupt in DMC

vblankwait1:
  bit $2002;clears vblank flag
  bpl vblankwait1

memclr:
  lda #$00
  sta $0000, x;x represents an offset of memory address
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne memclr ; loops clears memory 

vblankwait2:
  bit $2002
  bpl vblankwait2
  jsr ResetPalettes

main:
  inx
endlessLoop:

  jmp endlessLoop

palettes:
  ; Background Palette
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00

  ; Sprite Palette
  .byte $0f, $0, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00