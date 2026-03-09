.286
.model tiny
.code
org 100h

REG_VAL         equ 4c00h

Start:                          
                mov bx, 2222h
                mov cx, 3333h
                mov dx, 4444h
                mov si, 5555h
                mov di, 6666h
                mov bp, 7777h

                push 8888h
                pop ds

                push 9999h
                pop es

                mov ah, 01h
                int 21h

                mov ax, 4c00h
                int 21h

end             Start
