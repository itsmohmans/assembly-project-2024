; Mohamed Mansour 20210088

org 100h

.data
player1_health  dw 5
player2_health  dw 5
health_str      db "HEALTH"
welcome_str     db "Press `a` if Player 1 is ready, Press ^ (arrow up) if Player 2 is ready", 0h

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
  cmp welcome_str[si], 0
  jnz display_welcome


;draw health bars
; mov cx, player1_health
; mov ah,02h
; mov dl, '*'
; mov bx, 10      ; p1 health position
; int 21h

; push cx         ; save remaining health
; mov cx, bx      ; set cursor position
; mov ah, 02h          

jmp $           ; infinity loop

