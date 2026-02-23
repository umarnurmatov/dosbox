.286
.model tiny
.code

locals @@

org 100h

Start:          push 0
                pop es          ; сегмент таблицы прерываний
                mov bx, 4*08h   ; смещение 9го прерывания
                
                cli
                mov es:[bx], seg ResidentSeg     ; обработчик
                mov ax, cs
                mov es:[bx+2], ax               ; текущий сегмент
                sti

                mov ax, 3100h                   ; "terminate and stay resident"
                mov dx, offset EOP              ; dx = floor(размер_программы / 16) + 1
                                                ; в параграфах (16 байт)
                shr dx, 4
                inc dx
                int 21h


ResidentSeg     segment

UpdIRQ8         proc
                
                push ax bx cx es

                mov cx, word ptr ResidentSeg:toBeShown
                jcxz @@end

                push 0b800h
                pop es
                mov bx, (80d*5 + 40d)*2
                mov ah, 4eh

                mov al, 01h
                mov es:[bx], ax

@@end:          
                mov al, 20h
                out 20h, al                     ; EOI (end of interrupt) в контроллер прерываний

                pop es cx bx ax
                iret

UpdIRQ8         endp

toBeShown       dw 0

ResidentSeg     ends

end             Start
