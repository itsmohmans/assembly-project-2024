; Mohamed Mansour 20210088

org 100h

.data
p1_health  dw 5
p2_health  dw 5
health_str      db "HEALTH"
welcome_str     db "Press `a` if Player 1 is ready, Press arrow up if Player 2 is ready", 0h
ready_str       db 0ah, 0dh, "player ", 01h, " ready", 00h

.code
mov ax, @data
mov ds, ax

; display welcome
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
  cmp cl, 2               ; is both players ready?
  je start_game
  mov ah, 00h
  int 16h
  cmp al, 'a'
  je p1_ready

  cmp ah, 48h                 ; up arrow
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
  
  mov dl, ch              ; print current ready player in the placeholder
  add dl, 30h             ; convert to ascii
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
  cmp cl, 2               ; is both players ready?
  je start_game
  inc cl
  jmp wait_for_ready

start_game:
  mov ah, 00h
  mov al, 03h
  int 10h                   ; clear screen

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

; draw horizontal (health) bars
; cx = number of block to write
; dl = column
; dh = row
draw_horizontal_bar:
  add dl, 7           ; shift by the # of chars in "health"
  mov ah, 02h         ; interrupt for setting cursor position
  mov bh, 0           ; page 0 (from assembly help docs)
  int 10h
  ; push dx           ; save the orignial position [update: the whole program freaks out when I use this]
  mov ah, 09h         ; write character and attribute at cursor position
  mov al, '*'         ; char to write
  mov bl, 0Fh         ; white text attr
  mov ch, 0           ; cl has the health count, setting ch to 0 so that cx = count of '*' character
  int 10h
  inc dl              ; next col
  ret

; print "health" string
write_health:
  mov si, 0
  ; pop dx                  ; restore dx value
  write_health_loop:
    mov ah, 02h               ; for cursor position
    mov bh, 0                 ; page 0
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

jmp $                       ; infinity loop

