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

;draw health bars
; mov cx, p1_health
; mov ah,02h
; mov dl, '*'
; mov bx, 10                ; p1 health position
; int 21h

; push cx                   ; save remaining health
; mov cx, bx                ; set cursor position
; mov ah, 02h          

jmp $                       ; infinity loop

