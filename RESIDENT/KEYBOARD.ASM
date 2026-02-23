.286
.model tiny
.code
org 100h

Start:          push 0
                pop es          ; сегмент таблицы прерываний
                mov bx, 4*09h   ; смещение 9го прерывания
                
                cli
                mov es:[bx], offset UpdIRQ9     ; обработчик
                mov ax, cs
                mov es:[bx+2], ax               ; текущий сегмент
                sti

                mov ax, 3100h                   ; "terminate and stay resident"
                mov dx, offset EOP              ; dx = floor(размер_программы / 16) + 1
                                                ; в параграфах (16 байт)
                shr dx, 4
                inc dx
                int 21h


UpdIRQ9         proc
                
                push ax bx es

                push 0b800h
                pop es
                mov bx, (80d*5 + 40d)*2
                mov ah, 4eh

                in al, 60h
                mov es:[bx], ax

                in al, 61h
                or al, 80h                      ; выставляем старший бит порта
                out 61h, al
                and al, not 80h
                out 61h, al                     ; "мигнули" старшим битом

                mov al, 20h
                out 20h, al                     ; EOI (end of interrupt) в контроллер прерываний

                pop es bx ax
                iret

UpdIRQ9         endp

EOP:            

end             Start


