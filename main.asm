; Mohamed Mansour 20210088

org 100h

.data
p1_health       db 5
p2_health       db 5
health_str      db "HEALTH", 0h
welcome_str     db "Press `a` if Player 1 is ready, Press arrow up if Player 2 is ready", 0h
ready_str       db 0ah, 0dh, "player ", 01h, " ready", 00h ; 01h is just a placeholder
block           db 219          ; ascii for a block
hole_coords     db 40, 0        ; coordinates of of the hole in the wall (x, y)
wall_direction  db 1            ; 1 = down, -1 = up
player1_coords  db 2 DUP (-1)    ; coordinates of the first  player's bullet
player2_coords  db 2 DUP (-1)    ; coordinates of the second player's bullet

.code
mov ax, @data
mov ds, ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WELCOME SCREENS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov si, 0
mov ah, 02h
display_welcome:
  mov dl, welcome_str[si]
  int 21h
  inc si
  cmp welcome_str[si], 0    ; end of welcome string
  jnz display_welcome

mov cl, 0                   ; stores if 2 players are ready
; capture keyboard input
wait_for_ready:
  cmp cl, 2                 ; is both players ready?
  je start_game
  mov ah, 00h
  int 16h
  cmp al, 'a'
  je p1_ready

  cmp ah, 48h               ; up arrow
  je p2_ready

  jmp wait_for_ready

p1_ready:
  mov ch, 1                 ; current player
  call print_ready
  jmp check_ready_status

p2_ready:
  mov ch, 2
  call print_ready
  jmp check_ready_status

print_ready:
  mov si, 0

print_ready_loop:
  mov dl, ready_str[si]
  
  cmp dl, 01h
  jne print_char
  
  mov dl, ch                ; print current ready player in the placeholder
  add dl, 30h               ; convert to ascii
  jmp print_char

print_char:
  cmp dl, 00h               ; end of the str?
  je go_back
  mov ah, 02h
  int 21h
  inc si
  jmp print_ready_loop

go_back:
  ret

check_ready_status:
  cmp cl, 2                 ; is both players ready?
  je start_game
  inc cl
  jmp wait_for_ready

start_game:
  mov ah, 00h
  mov al, 03h               ; for 80x25 terminal/vid mode
  int 10h                   ; clear screen

; registers used so far:
; cl: to store # of ready players (unneeded now)
; ch: to store which player is ready (unneeded now)
; ah, al, dl: for interrupt-related operations

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; INTERFACE SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; draw player 1 health bar
mov cl, p1_health
mov dl, 0                   ; starting from col 0
mov dh, 0                   ; row = 0
call draw_horizontal_bar
mov dx, 0
call write_health

; draw player 2 health bar
mov cl, p2_health
mov dl, 65                  ; starts at col 65
mov dh, 0
call draw_horizontal_bar
mov dl, 65
mov dh, 0
call write_health

; ------------ draw players blocks ------------
; player 1 block
mov dl, 0                   ; col = 0
mov dh, 7                   ; row = 7
mov di, 10                  ; height = 10
mov cx, 5                   ; width = 5
mov bl, 01h                 ; color = blue
mov al, block
call draw_vertical_block

; player 2 block
mov dl, 75                  ; col = 0
mov dh, 10                  ; row = 7
mov di, 10                  ; height = 10
mov cx, 5                   ; width = 5
mov bl, 04h                 ; color = red
mov al, block
call draw_vertical_block

; ------------- draw the wall -----------------
mov di, 25                  ; height
mov dl, 40                  ; starts at column 40
mov dh, 0                   ; row 0
mov cx, 1                   ; print 1 block (width)
mov bl, 0Eh                 ; color = yellow
mov al, block
call draw_vertical_block


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MAIN GAME LOOP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main_loop:
  call move_wall
  call check_input
  call move_bullets
  jmp main_loop



; --------------------------------------------------------------------------
; draw horizontal (health) bars
; cx = number of block to write
; dl = column
; dh = row
draw_horizontal_bar:
  add dl, 7                 ; shift by the # of chars in "health"
  mov ah, 02h               ; interrupt for setting cursor position
  mov bh, 0                 ; page 0 (from assembly help docs)
  int 10h
  ; push dx                 ; save the orignial position [update: the whole program freaks out when I use this]
  mov ah, 09h               ; write character and attribute at cursor position
  mov al, '*'               ; char to write
  mov bl, 0Fh               ; white text attr
  mov ch, 0                 ; cl has the health count, setting ch to 0 so that cx = count of '*' character
  int 10h
  inc dl                    ; next col
  ret

; print "health" string
write_health:
  mov si, 0
  ; pop dx                  ; restore dx value
  write_health_loop:
    mov ah, 02h             ; for cursor position
    mov bh, 0               ; page 0
    int 10h
    mov ah, 09h
    mov al, health_str[si]
    mov bl, 0fh
    mov cx, 1               ; count of each character
    int 10h
    inc dl                  ; next col
    inc si
    cmp health_str[si], 0h
    jnz write_health_loop
  ret


; draw a vertical block, used for the wall, the moving wall hole, or players blocks
; cx = width
; dl = starting col
; dh = starting row
; di = max rows (aka height)
; bl = char attribute (color)
draw_vertical_block:
  mov bh, 0
vertical_block_loop:
  mov ah, 02h
  int 10h
  mov ah, 09h
  ; mov al, block
  int 10h
  inc dh                    ; go to the next row
  dec di                    ; counter for the height
  jnz vertical_block_loop
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WALL MOVEMENT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
move_wall:
  ; erase the previous hole block with yellow wall
  mov dl, hole_coords[0]
  mov dh, hole_coords[1]
  
  cmp wall_direction, -1
  je cover_bottom_wall
  mov cx, 1                 ; width and height = 1
  mov di, 1
  mov bl, 0Eh               ; yellow
  mov al, block
  call draw_vertical_block

cover_bottom_wall:
  add dh, 5
  mov cx, 1                 ; width and height = 1
  mov di, 1
  mov bl, 0Eh               ; yellow
  mov al, block
  call draw_vertical_block

  ; update wall position
  mov al, wall_direction
  add hole_coords[1], al    ; move up or down
  cmp al, 1                 ; if it's moving down
  jne check_top
  call check_bottom

  jmp draw_new_hole

check_bottom:
  cmp hole_coords[1], 22    ; check if reached bottom. TODO: change it to 20?
  je set_hole_dir_up
  ret

set_hole_dir_up:
  mov wall_direction, -1    ; change hole move direction to up
  ret

set_hole_dir_down:
  mov wall_direction, 1
  mov hole_coords[1], 1     ; reset starting coords
  ret

check_top:
  mov ah, hole_coords[1]
  cmp hole_coords[1], 0     ; check if reached top
  jbe set_hole_dir_down
  jmp draw_new_hole

draw_new_hole:
  mov dl, hole_coords[0]
  mov dh, hole_coords[1]
  mov bl, 00h               ; black block
  mov cx, 1
  mov di, 5                 ; hole height = 5
  mov al, ' '
  call draw_vertical_block
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CHECK INPUT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check_input:
  mov ah, 01h              ; non-blocking keyboard input
  int 16h
  jz no_input              ; no key pressed

  ; TODO: if either bullets' variables are already set, return
  mov ah, 00h
  int 16h
  cmp al, 'a'
  je fire_player1_bullet
  cmp ah, 48h               ; check for arrow up key
  je fire_player2_bullet

no_input:
  ret

fire_player1_bullet:
  mov dl, 6                 ; starting col
  mov dh, 12                ; starting row
  mov bl, 01h               ; blue
  mov player1_coords[0], dl
  mov player1_coords[1], dh
  call add_bullet
  ret

fire_player2_bullet:
  mov dl, 74                ; starting col
  mov dh, 15                ; starting row
  mov bl, 04h               ; red
  mov player2_coords[0], dl
  mov player2_coords[1], dh
  call add_bullet
  ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MOVE BULLET ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
add_bullet:
  mov cx, 1
  mov di, 1
  mov al, block
  call draw_vertical_block
  ret

move_bullets:
  ; TODO:
  ; if bullet 1 is set, move it
  ; if bullet 2 is set, move it
  ; once either finish (pass through or collide), remove it, and reset their vars
  cmp player1_coords[0], -1
  jne move_p1_bullet

  move_bullets_p2:
    cmp player2_coords[0], -1
    jne move_p2_bullet
  ret

move_p1_bullet:
  ; remove previous block
  mov dl, player1_coords[0]
  mov dh, player1_coords[1]
  mov cx, 1                 ; width
  mov di, 1                 ; height
  mov al, ' '
  call draw_vertical_block
  
  inc dl
  mov player1_coords[0], dl
  mov dh, player1_coords[1]
  mov al, block
  mov bl, 01h               ; red
  mov di, 1
  call draw_vertical_block
  ; TODO: check for collision with the wall or its hole
  jmp move_bullets_p2

move_p2_bullet:
  ; remove previous block
  mov dl, player2_coords[0]
  mov dh, player2_coords[1]
  mov cx, 1                 ; width
  mov di, 1                 ; height
  mov al, ' '
  call draw_vertical_block
  
  dec dl
  mov player2_coords[0], dl
  mov dh, player2_coords[1]
  mov al, block
  mov bl, 04h               ; red
  mov di, 1
  mov cx, 1
  call draw_vertical_block
  ; TODO: check for collision
  ret

jmp $                       ; infinity loop
