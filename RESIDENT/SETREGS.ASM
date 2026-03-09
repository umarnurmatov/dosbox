.286
.model tiny
.code
org 100h

REG_VAL                 equ 4c00h

MASK_FLAG_CF            equ 0001h

MASK_FLAG_PF            equ 0004h

MASK_FLAG_AF            equ 0010h

MASK_FLAG_ZF            equ 0040h

MASK_FLAG_SF            equ 0080h

MASK_FLAG_TF            equ 0100h

MASK_FLAG_IF            equ 0200h

MASK_FLAG_DF            equ 0400h

MASK_FLAG_OF            equ 0800h

Start:                          

                push    40h
                pop     es
                mov     ax, es:[17h]

                jmp Start

                mov     bx, 0002h
                mov     cx, 0003h
                mov     dx, 0004h
                mov     si, 0005h
                mov     di, 0006h
                mov     bp, 0007h

                push    0008h
                pop     ds

                push    0009h
                pop     es

                mov     ah, 0ffh
                sahf


                mov     ah, 01h
                int     21h

                mov     ax, 4c00h
                int     21h

end             Start
