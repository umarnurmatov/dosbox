.286
.model tiny
.code
org 100h

REG_VAL         equ 4c00h

Start:                          
                mov bx, 0002h
                mov cx, 0003h
                mov dx, 0004h
                mov si, 0005h
                mov di, 0006h
                mov bp, 0007h

                push 0008h
                pop ds

                push 0009h
                pop es

                mov ah, 01h
                int 21h

                mov ax, 4c00h
                int 21h

end             Start
