;S Nathan
;HW 08 final version

;start defines
define clearL $08
define clearH $09
define snakeDir $02 ;store direction of snake in memory value 02
define up $01 ;define directions as 01-04 for easier processing after conversion from ASCII
define left $02
define right $03
define down $04
define snakeLength $01 ;snakelength memory
define snakeHeadL $10
define snakeHeadH $11
define snakeBodyStartL $12 
define snakeBodyStartH $13 ;not needed but helps
define snakeTailL $4 ;not needed but easier to draw. After shift loop, last values are copied to these memory locations 
define snakeTailH $5
define offset_counter $3  ;offset counter for shifting memory values in a loop
define appleL $6 ;location to store apple position
define appleH $7
define lastkeyPressed $ff ;last key pressed
define random $fe ;random
define white $01 ;white pixel color
define black $00 ;black pixel color
define red $02 ;red pixel color
define win_color $5 ;win color text currently set to green
define lose_color $2 ;lose color text set to red 

start: ;start routine for first run or restarting game
jsr clear ;clear the display by filling in black
jsr setup ;initialize starting position for head,body,tail,length and down direction
jmp gameloop ;gameloop

clear: ;clears boards
LDX #$ec 
clear_snake: ;zero out memory queue for snake
    LDA #$00
    sta snakeBodyStartL,x
    DEX
    cpx #$ff
    bne clear_snake
LDA #$00
STA clearL
LDA #$02
STA clearH
clear_everything: ;clears displays with code taken from assignment 5
  lda #00 
  ldx #$00
  sta (clearL, x)  
  inc clearL     
  LDX clearL
  CPX #$ff	
  BNE clear_everything
  BEQ switchrows
switchrows:
  LDX #$00       
  sta (clearL, x)
  inc clearH    
  lda #$00
  sta clearL
  ldx clearH
  CPX #$06  
  BNE clear_everything
  BEQ clear_rts
clear_rts:
rts

setup: ;set up starting values
  setup_Len: ;initial snake length of 04
    LDA #$04
    ;lda #$EC ;one before max length
    STA snakeLength
  setup_Head: ;initial snake head position
    LDA #$03
    STA snakeHeadH
    LDA #$50
    STA snakeHeadL
  setup_Tail: ;tail is zero
    LDA #$00
    STA snakeBodyStartH
    LDA #$00
    STA snakeBodyStartL
  setup_Dir: ;define initial starting dir of down
    LDA #$74 
    STA lastkeyPressed
    LDA #$04
    STA snakeDir
  setup_Apple: ;apple starting
    LDA random
    STA appleL
    LDA random
    AND #$03
    STA appleH
    INC appleH
    INC appleH
  setup_offset: ;offset counter is set to 0
    LDA #$00
    STA offset_counter
rts

gameloop:

  jsr updateSnake ;subprocess for calculating position, lastkey, direction, and boundary issues
  jsr drawSnake ;draw three pixels of snake
  jmp gameloop ;loop again

updateSnake:
  jsr slowDown
  jsr setDir ;pull ASCII key pressed and translate into 1-up,2-left,3right,4-down
  jsr checkCollision ;take last key pressed and see if it will result in hitting edge and if so, end game.  Only bottom boundary is coded so far
  jsr updatePositions ;shift positions down the queue
  jsr updateHead ;calculate where head pixel will be placed depending on direction.  Includes processes for down and right movement so far.
  jsr checkCollision_self ;check if update head lands on a currently white pixel before actually drawing 
  jsr applecheck
  rts
setDir: 
  LDA lastkeyPressed
  lowercase:  ;check first for lowercase
    CMP #$77 
    BEQ set_up
    CMP #$73
    BEQ set_down
    CMP #$61
    BEQ set_left
    CMP #$64
    BEQ set_right
  uppercase: ;check for uppercase
    CMP #$57 
    BEQ set_up
    CMP #$53
    BEQ set_down
    CMP #$41
    BEQ set_left
    CMP #$44
    BEQ set_right
  	jmp dir_leave ;if invalid key rts
    set_down:
      LDA snakeDir
      CMP #up
      BEQ dir_leave ;leave if the previous direction was up so we cant double back on ourself 
      LDA #down
      STA snakeDir
      rts
    set_up:
      LDA snakeDir
      CMP #down ;no double back check
      BEQ dir_leave
      LDA #up
      STA snakeDir
      rts
    set_left:
      LDA snakeDir
      CMP #right
      BEQ dir_leave
      LDA #left
      STA snakeDir
      rts
    set_right:
      LDA snakeDir
      CMP #left
      BEQ dir_leave
      LDA #right
      STA snakeDir
      rts
    dir_leave:
      rts
checkCollision: ;check wall collision
  LDA snakeDir ;load snake dir before we draw to see if this pixel will be out of bounds
  CMP #down ;branch based on direction
  BEQ check_down
  CMP #up
  BEQ check_up
  CMP #left
  BEQ check_left
  CMP #right
  BEQ check_right
  rts
    check_down: 
      LDA snakeHeadH ;load headH
      CMP #$05 		;if in quad 5 see if carry flag gets set when 20 is added as that would indicate quad 6
      BEQ check_down_2
      BNE continue
        check_down_2: 
          LDA snakeHeadL
          CLC 
          ADC #$20
          BCC continue ;if no carry, continue as no wall was hit
          BCS boundary_hit ; carry is set so end game
    check_up:
      LDA snakeHeadH ;same logic as check down just subtracting 20
      CMP #$02
      BEQ check_up_2
      BNE continue
        check_up_2:  
          LDA snakeHeadL
          SEC
          SBC #$20
          BCS continue
          BCC boundary_hit
    check_left: ;subtract 1, and with #$1f to see if left boundary was hit
      LDA snakeHeadL
      SEC
      SBC #$01
      and #$1F
      CMP #$1f 
      BEQ boundary_hit
      BNE continue 
    check_right: ;simple and with #$1f if snake is still heading right it would be out of bounds so end game
      LDA snakeHeadL
      and #$1F
      CMP #$1F
      BEQ boundary_hit
      BNE continue
    checkCollision_self: ;called separately just added here for organization 
      LDX #$00 
      LDA (snakeHeadL,x) ;head is updated in memory but not yet drawn
      cmp #$01 ;we load what is currently stored in the new head's position and see if it is white
      BNE continue ;if not, continue
      BEQ checkCollision_self_tail ;if it is equal, we either hit self or the snake tail that would be black on the next draw
      rts
      checkCollision_self_tail:
        LDA snakeHeadL ;load snaketail and head 
        CMP snakeTailL
        BNE boundary_hit ;if they are not equal then we hit ourself
        LDA snakeHeadH
        CMP snakeTailH
        BNE boundary_hit
        BEQ continue ;if the snakeheadH and snakeheadL are equal to tailL and tailH then we hit the tail that is currently white but will be black on net draw which shouldn't be a game over
      continue: ;return as snake is clear
        CLC
        rts
      boundary_hit: ;jump to end/game over sequence if we hit self or wall
        CLC
        jmp end
   
updatePositions: ;shift values down the queue
LDX snakeLength ;load our snake length
DEX  ;subtract by one
  shiftloop:
    LDA snakeHeadL,x ;load second to last first and shift it 2 memory locations to the right
    sta snakeBodyStartL,x ;store
    DEX ;subtract one till we end by shifting head positions to the first body position
    cpx #$ff ;check if subtract past 0 and if so end the shift. bpl was limited to snake length of 82 for some reason so this was the only solution.  Our snake length will never go above ef so we dont have to worry about odd behaviors.
    bne shiftloop ;shift again
    beq copytail ;once done new branch
  copytail: ;copy our last 2 memory locations in the queue to a defined tail memory locations for easier reference by other functions 
    clc
    LDX snakeLength 
    LDA snakeHeadL,x
    sta snakeTailL
    INX
    LDA snakeHeadL,x
    sta snakeTailH
rts
updateHead: ;update where our next head will be based on key direction
  LDA snakeDir ;direction is already set so now we calculate
  CMP #$01 ;1 is w updating up. easier to assign 4 numbers instead of ascii values for this stage
  BEQ update_up
  CMP #$02 ;2 left
  BEQ update_left
  CMP #$03 ;3 right
  BEQ update_right
  CMP #$04 ;4 down
  BEQ update_down   ;update down
    update_up: ;subtract 20 and check carry flags to see if we need to subtract our hibyte
      LDA snakeHeadL
      SEC
      SBC #$20
      STA snakeHeadL
      jsr incHead_Up
      rts
        incHead_Up:
          BCS incHead_noshift_up
          BCC incHead_shift_up
        incHead_noshift_up:
          CLC
          rts
        incHead_shift_up:
          dec snakeHeadH
          CLC
          rts    
    update_left: ;simple subtract one 
      LDA snakeHeadL
      SEC
      SBC #$01
      STA snakeHeadL
      clc
      rts
    update_right: ;add one
      LDA snakeHeadL
      CLC
      ADC #$01
      STA snakeHeadL
      rts
    update_down: ;add 20 and check carry flag for hiByte calculation
      LDA snakeHeadL
      CLC
      ADC #$20
      STA snakeHeadL
      jsr incHead_Down
        incHead_Down:
          BCC incHead_noshift_down
          BCS incHead_shift_down
        incHead_shift_down:
          CLC
          inc snakeHeadH
          rts
        incHead_noshift_down:
          CLC
          rts
    rts
applecheck: ;check if we landed on an apple before we draw
  LDA snakeHeadL 
  CMP appleL
  BNE continue
  LDA snakeHeadH
  CMP appleH
  bne continue
  BEQ applecheck_add ;if our snake and apple position we add 2 to snakelength and generate a new apple
  applecheck_add: ;add to snake length
    LDA snakeLength 
    CLC 
    ADC #$02
    STA snakeLength   
    CMP #$ee ;check here if the new added snake length is ee which is the max length our snake can be before overwriting random byte and lastkey pressed 
    BEQ game_win ;game win
  applecheck_new:
    LDA random ;generate new apple position
    STA appleL
    LDA random
    AND #$03 
    STA appleH
    INC appleH
    INC appleH ;get a value between 2 and 5 for hiByte
    STA (appleL,x)  
rts

drawSnake: ;draw routine 
  draw_Head: ;draw head
    LDX #$00
    LDA #white
    STA (snakeHeadL,x)
  draw_Body:
    LDX #$00
    LDA #white
    STA (snakeBodyStartL,x)
  draw_Tail:
    LDX #$00
    LDA #black
    STA (snakeTailL,x)
  draw_Apple: ;draw apple last to overwrite snake body in case we spawn the apple inside the snake itself 
    LDX #$00 
    ;LDA #red
    LDA random
    and #$0d ;get a pixel color that is not white or black to draw as a flashing apple
    CLC
    ADC #$02
    STA (appleL,x)
rts

slowDown: ;slow down
  LDA snakeLength ;use snake length as starting position for loop. The lower the snake length is the more NOP commands we run and as length increases, less NOPs are ran which would make the snake faster
  slowLoop:
    NOP 
    ADC #$01 ;add 1 until we set carry flag 
    BCC slowLoop
    CLC
    rts

reset_check:
  LDA lastkeyPressed ;new game if n/N pressed and quits if q/Q pressed
  CMP #$6e ;upper and lowercase n for new game
  BEQ reset_new
  CMP #$4e
  BEQ reset_new
  CMP #$51 ;upper/lower q case for ending game
  BEQ reset_end
  CMP #$71
  BEQ reset_end
  jmp reset_check ;endless loop until n or q is pressed
	reset_new:
		jmp start ;start routine that clears memory and sets up the game again
	reset_end:
                jsr clear ;clear display and then jump to end_quit routine which runs brk
		jmp end_quit 
game_win: ;display text WIN for winning the game
  LDA #win_color
  w_1:
  STA $0303
  STA $0323
  STA $0343
  STA $0363
  STA $0383
  STA $03a3
  STA $03a4
  STA $03a5
  STA $03a6
  STA $03a7
  STA $03a8
  STA $0386
  STA $0366
  STA $03a9
  STA $0389
  STA $0369
  STA $0349
  STA $0329
  STA $0309
  i_1:
  STA $0310
  STA $0330
  STA $0350
  STA $0370
  STA $0390
  STA $03b0
  n_1:
  STA $0316
  STA $0336
  STA $0356
  STA $0376
  STA $0396
  STA $03b6
  n_2:
  STA $0316
  STA $0337
  STA $0358
  STA $0379
  STA $039a
  STA $03bb
  n_3:
  STA $03bb
  STA $039b
  STA $037b
  STA $035b
  STA $033b
  STA $031b
  jsr nq_draw
  jmp reset_check
end: ;display lose for losing the game
  LDA #lose_color
    l:
  STA $0300
  STA $0320
  STA $0340
  STA $0360
  STA $0380
  STA $03a0
  STA $03c0
  STA $03c1
  STA $03c2
  STA $03c3
  0:
  STA $0308
  STA $0309
  STA $030a
  STA $030b
  STA $0328
  STA $0348
  STA $0368
  STA $0388
  STA $03a8
  STA $03c8
  STA $03c9
  STA $03ca
  STA $03cb
  STA $03cc
  STA $03ac
  STA $038c
  STA $036c
  STA $034c
  STA $032c
  STA $030c
  e:
  STA $03db
  STA $03bb
  STA $039b
  STA $037b
  STA $035b
  STA $033b
  STA $031b
  STA $031c
  STA $031d
  STA $031e
  STA $031f
  STA $037c
  STA $037d
  STA $037e
  STA $03dc
  STA $03dd
  STA $03de
  STA $03df
  s:
  STA $0311
  STA $0312
  STA $0313
  STA $0314
  STA $0315
  STA $0316
  STA $0331
  STA $0351
  STA $0371
  STA $0372
  STA $0373
  STA $0374
  STA $0375
  STA $0376
  STA $03b6
  STA $0396
  STA $0396
  STA $03b6
  STA $03d6
  STA $03d5
  STA $03d4
  STA $03d3
  STA $03d2
  STA $03d1
  jsr nq_draw
  jmp reset_check

nq_draw: ;draw n and q for new game or quit game 
  lda #$06
  new_n:
  sta $042d
  sta $044d
  sta $046d
  sta $048d
  sta $04ad
  sta $044e
  sta $044f
  sta $0450
  sta $0470
  sta $0490
  sta $04b0
  stop_q:
  sta $050d
  sta $050e
  sta $050f
  sta $0510
  sta $0530
  sta $0550
  sta $0570
  sta $0590
  sta $05b0
  sta $05b1
  sta $052d
  sta $054d
  sta $054e
  sta $054f
  rts

end_quit: ;brk
brk