.286
.model tiny
.code
locals @@
org 100h

VRAMSEGMENT	equ 0b800h
ARGCNT_ADDR	equ 80h
CMDARG_ADDR	equ 81h
COLATTRIB	equ 00000100b
SCREENH		equ 19h
SCREENW		equ 50h
B_OFFSET    equ 4h
CTRL_CHR    equ 2fh
DEF_BORD    equ 023h

POPUP_TXT_STR_LEN   equ 7
WORD_BYTES          equ 2

Start:          push 0
                pop es                          ; сегмент таблицы прерываний
                mov bx, 4*08h                   ; смещение 8го прерывания
                cli
                mov es:[bx], offset UpdIRQ0     ; обработчик
                mov ax, cs
                mov es:[bx+2], ax               ; текущий сегмент
                sti

                mov bx, 4*09h                   ; смещение 9го прерывания
                mov ax, es:[bx]
                mov word ptr OldIRQ9Vec, ax 
                mov ax, es:[bx+2]
                mov word ptr OldIRQ9Vec+2, ax
                cli
                mov es:[bx], offset UpdIRQ1     ; обработчик
                mov ax, cs
                mov es:[bx+2], ax               ; текущий сегмент
                sti

                mov ax, 3100h                   ; "terminate and stay resident"
                mov dx, offset EOP              ; dx = floor(размер_программы / 16) + 1
                                                ; в параграфах (16 байт)
                shr dx, 4
                inc dx
                int 21h


;-------------------------------------
; Update IRQ 0
;-------------------------------------
UpdIRQ0         proc

PUSHED_REG_CNT  equ 11

                push ax bx cx dx si di bp sp ds ss es
                mov bp, sp

                push cs
                pop ds

                mov cx, ShowInterface
                jcxz @@end

                lea si, PopupTxt + 3*WORD_BYTES
                mov bx, bp
                add bx, WORD_BYTES*PUSHED_REG_CNT
                mov cx, 4
@setregs:       
                mov byte ptr al, [bx]
                add ax, '0'
                mov byte ptr [si], al
                dec bx
                add si, WORD_BYTES 


                mov byte ptr al, [bx]
                add ax, '0'
                mov byte ptr [si], al
                dec bx

                add si, (POPUP_TXT_STR_LEN - 3)*WORD_BYTES
                loop @setregs
                

                push VRAMSEGMENT
                pop es
                mov di, (SCREENW*5 + SCREENW/2)*WORD_BYTES
                mov si, offset PopupTxt
                mov cx, POPUP_TXT_LEN

                call PrintStr

@@end:

                mov al, 20h
                out 20h, al                     ; EOI (end of interrupt) в контроллер прерываний

                pop es ss ds sp bp di si dx cx bx ax
                iret

UpdIRQ0         endp
;-------------------------------------


;-------------------------------------
; Update IRQ 1
;-------------------------------------
UpdIRQ1         proc

                push ax bx cx dx ds                

                push cs
                pop ds

                in al, 60h
                cmp al, 02h                     ; scan code of '!'
                je @@trigger

                pop ds dx cx bx ax
                jmp cs:[OldIRQ9Vec]

@@trigger:
                in al, 61h
                or al, 80h                      ; выставляем старший бит порта
                out 61h, al
                and al, not 80h
                out 61h, al                     ; "мигнули" старшим битом

                mov al, 20h
                out 20h, al                     ; EOI (end of interrupt) в контроллер прерываний
                
                not ShowInterface

                pop ds dx cx bx ax
                iret

UpdIRQ1         endp
;-------------------------------------


;-------------------------------------
; Print string on screen
; 
; Entry: DS:SI --> string in format [[ASCII, color attrib], ...]
;        ES:DI --> vram addr
;        CX    =   string length
; Destr: SI, DI, CX
;-------------------------------------

PrintStr        proc
                
@@loopv:        lodsw			; al = ds:[si]; ++si
                stosw			; es:[di] = ah; ++di
                dec cl
                jnz @@loopv

                ret
PrintStr        endp

;-------------------------------------

OldIRQ9Vec      dd 0 
ShowInterface   dw 0
Symbol          db 3h

COL_NAME            equ 00000100b
COL_VAL             equ 00000100b

PopupTxt            db 'a', COL_NAME, 'x', COL_NAME, ' ', COL_VAL, 2 dup('0', COL_VAL)
                    db 'b', COL_NAME, 'x', COL_NAME, ' ', COL_VAL, 2 dup('0', COL_VAL)
                    db 'c', COL_NAME, 'x', COL_NAME, ' ', COL_VAL, 2 dup('0', COL_VAL)
                    db 'd', COL_NAME, 'x', COL_NAME, ' ', COL_VAL, 2 dup('0', COL_VAL)

POPUP_TXT_BYTES     equ $ - PopupTxt
POPUP_TXT_LEN       equ POPUP_TXT_BYTES / 2


EOP:            

end             Start


