.db "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

.org $8000

.define PPUCTRL $2000
.define PPUMASK $2001
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define OAMDMA $4014

.define JOYPAD1 $4016
.define JOYPAD2 $4017

.define SCROLL_X $00
.define SCROLL_Y $01
.define SPRITE_X $02
.define SPRITE_Y $03
.define buttons $04

.define OAMDMA_RAM_PAGE $0200

; Page 2 of RAM is used as a copy of the OAM for DMA purposes

start:
    LDA #%10010000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK
    
    ; load background palette
    LDA #$3f
    STA PPUADDR
    LDA #0
    STA PPUADDR

    LDA #$11
    STA PPUDATA
    LDA #$23
    STA PPUDATA
    LDA #$28
    STA PPUDATA
    LDA #$0F
    STA PPUDATA

    ; load aiv logo on nametables
    LDA #$20
    STA PPUADDR
    LDA #0
    STA PPUADDR
    JSR load_nametable

    LDA #$24
    STA PPUADDR
    LDA #0
    STA PPUADDR
    JSR load_nametable

    ; load sprite palette
    LDA #$3f
    STA PPUADDR
    LDA #$11
    STA PPUADDR

    LDA #$0F
    STA PPUDATA
    LDA #$30
    STA PPUDATA
    LDA #$16
    STA PPUDATA
    
    ; load sprites
    LDA #116  ; initial X coord of the card
    STA $14
    STA SPRITE_X
    LDA #104  ; initial y coord of the card
    STA $15
    STA SPRITE_Y
    LDA #$48 ; card first sprite index
    LDY #0
    JSR load_card

loop:
    JMP loop

load_card:
    PHA
    LDA #3
    STA $10
    LDA #4
    STA $11
    PLA
inner_card_loop:
    JSR load_sprite_on_ram
    PHA
    LDA $14 ; 
    CLC     ;
    ADC #8  ; increment X by 8 pixels
    STA $14 ;
    PLA
    ADC #1   ; increment tile index by one in the row
    DEC $10
    BNE inner_card_loop
outer_card_loop:
    ADC #13
    PHA
    LDA #3
    STA $10
    LDA $15 ;
    CLC     ;
    ADC #8  ; increment Y by 8 pixels
    STA $15 ;

    LDA $14 ; 
    SBC #23 ; decrement X by 24 pixels
    STA $14 ;
    PLA
    DEC $11
    BNE inner_card_loop
    RTS

; function to load a single 8x8 sprite ($14: x coord, $15: y coord, A: tile index)
load_sprite_on_ram:
    PHA
    LDA $15
    STA OAMDMA_RAM_PAGE,Y
    INY
    PLA
    STA OAMDMA_RAM_PAGE,Y
    INY
    PHA
    LDA #0
    STA OAMDMA_RAM_PAGE,Y
    INY
    LDA $14
    STA OAMDMA_RAM_PAGE,Y
    INY
    PLA
    RTS

load_nametable:
    LDX #0     ; pattern table index
    LDY #0     ; "void" pattern table index
    LDA #$10  
    STA $10    ; 16 hex cycle (x2)
    STA $11    ; 16 row cycle
inner_loop_first_16:
    STX PPUDATA
    INX
    DEC $10
    BNE inner_loop_first_16
    STA $10
inner_loop_last_16:
    STY PPUDATA
    DEC $10
    BNE inner_loop_last_16
outer_loop:
    STA $10
    DEC $11
    BNE inner_loop_first_16
    RTS

readjoy:
    LDA #$01
    STA JOYPAD1
    STA buttons
    LSR A
    STA JOYPAD1
joyloop:
    LDA JOYPAD1
    LSR A 
    ROL buttons
    BCC joyloop
    RTS

move_card_left:
    TYA
    PHA
    ; check for boundry
    LDY SPRITE_X
    BEQ no_move_left

    LDY #3
    LDA #12
    STA $20
move_card_left_loop:
    LDA OAMDMA_RAM_PAGE,Y
    CLC
    ADC #$FF
    STA OAMDMA_RAM_PAGE,Y
    INY
    INY
    INY
    INY
    DEC $20
    BNE move_card_left_loop
    LDY #3
    LDA OAMDMA_RAM_PAGE,Y
    STA SPRITE_X
no_move_left:
    PLA
    TAY
    RTS

move_card_right:
    TYA
    PHA
    ; check for boundry
    LDA SPRITE_X
    CLC
    ADC #24
    BEQ no_move_right

    LDY #3
    LDA #12
    STA $20
move_card_right_loop:
    LDA OAMDMA_RAM_PAGE,Y
    CLC
    ADC #$01
    STA OAMDMA_RAM_PAGE,Y
    INY
    INY
    INY
    INY
    DEC $20
    BNE move_card_right_loop
    LDY #3
    LDA OAMDMA_RAM_PAGE,Y
    STA SPRITE_X
no_move_right:
    PLA
    TAY
    RTS

move_card_up:
    TYA
    PHA
    ; check for boundry
    LDA SPRITE_Y
    CLC
    ADC #248
    BEQ no_move_up

    LDY #0
    LDA #12
    STA $20
move_card_up_loop:
    LDA OAMDMA_RAM_PAGE,Y
    CLC
    ADC #$FF
    STA OAMDMA_RAM_PAGE,Y
    INY
    INY
    INY
    INY
    DEC $20
    BNE move_card_up_loop
    LDA OAMDMA_RAM_PAGE
    STA SPRITE_Y
no_move_up:
    PLA
    TAY
    RTS

move_card_down:
    TYA
    PHA
    ; check for boundry
    LDA SPRITE_Y
    CLC
    ADC #57
    BEQ no_move_down

    LDY #0
    LDA #12
    STA $20
move_card_down_loop:
    LDA OAMDMA_RAM_PAGE,Y
    CLC
    ADC #$01
    STA OAMDMA_RAM_PAGE,Y
    INY
    INY
    INY
    INY
    DEC $20
    BNE move_card_down_loop
    LDA OAMDMA_RAM_PAGE
    STA SPRITE_Y
no_move_down:
    PLA
    TAY
    RTS

nmi:
    PHA
    JSR readjoy ; read input each nmi
    LDA buttons
    ; reject up+down and left+right
    AND #%00001010    
    LSR A
    AND buttons  
    BEQ not_updown_or_leftright
    PLA
    RTI
not_updown_or_leftright:
    ; left check
    LDA buttons
    AND #%00000010  
    BEQ no_left
    DEC SCROLL_X
    DEC SCROLL_X
    JSR move_card_left
no_left:
    ; right check
    LDA buttons
    AND #%00000001  
    BEQ no_right
    INC SCROLL_X
    INC SCROLL_X
    JSR move_card_right
no_right:
    ; up check
    LDA buttons
    AND #%00001000  
    BEQ no_up
    JSR move_card_up
no_up:
    ; down check
    LDA buttons
    AND #%00000100  
    BEQ no_down
    JSR move_card_down
no_down:
    LDA SCROLL_X
    STA PPUSCROLL
    LDA #0
    STA PPUSCROLL
    LDA #$02
    STA OAMDMA
    PLA
    RTI

irq:
    RTI

.goto $FFFA

.dw nmi
.dw start
.dw irq

.incbin cards.chr
.incbin aiv256.chr