; Mohamed Mansour 20210088

org 100h

.data
player1_health db 5
player2_health db 5

.code
mov ax, @data
mov ds,ax

;draw health bars
mov cx, player1_health
mov ah,02h
mov dl, '*'
mov bx,10 ;p1 health position

push cx ; save remaining health
mov cx, bx ; set cursor position
mov ah, 02h
; 