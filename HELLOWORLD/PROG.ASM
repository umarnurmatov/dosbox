.model tiny
.code
org 100h

CRLF equ 0dh, 0ah

Start:
mov ah, 09h
mov dx, offset String
int 21h

mov ax, 004ch
int 21h

String: db 'Meow', CRLF, 'MEOW$'
end Start