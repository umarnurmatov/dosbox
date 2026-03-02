.286
.model tiny
.code
locals @@
org 100h

VRAMSEGMENT	            equ 0b800h
SCR_H		            equ 19h
SCR_W		            equ 50h
WB                      equ 2                       ; bytes in word

Start:          push    0
                pop     es                          ; сегмент таблицы прерываний
                mov     bx, 4*08h                   ; смещение 8го прерывания
                cli    
                mov     es:[bx], offset UpdIRQ0     ; обработчик
                mov     ax,cs
                mov     es:[bx+2], ax               ; текущий сегмент
                sti    

                mov     bx, 4*09h                   ; смещение 9го прерывания
                mov     ax, es:[bx]
                mov     word ptr OldIRQ9Vec, ax 
                mov     ax, es:[bx+2]
                mov     word ptr OldIRQ9Vec+2, ax
                cli    
                mov     es:[bx], offset UpdIRQ1     ; обработчик
                mov     ax, cs
                mov     es:[bx+2], ax               ; текущий сегмент
                sti    

                lea     si, RegNmTbl
                lea     di, DrawBuffer+(DRAW_BUFFER_W+1)*WB
                push    cs
                pop     es
                call    LoadRegNm

                mov     bx, DRAW_BUFFER_W
                lea     di, DrawBuffer
                lea     si, BorderTbl
                mov     dx, DRAW_BUFFER_H
                call    RectBorder

                mov     ax, 3100h                   ; "terminate and stay resident"
                mov     dx, offset EOP              ; dx = floor(размер_программы / 16) + 1
                                                    ; в параграфах (16 байт)
                shr     dx, 4
                inc     dx
                int     21h


;--------------------------------------------------------------------------
; Update IRQ 0
;--------------------------------------------------------------------------
UpdIRQ0         proc

                push    ax bx cx dx si di bp sp ds ss es
                mov     bp, sp

                push    [bp+WB*11+4]           ; cs
                push    [bp+WB*11+2]           ; ip

                push    cs
                pop     ds

                push    ds
                pop     es

                mov     cx, ShowInterface
                jcxz    @@End

                ; TODO
                ; lea     si, DrawBuffer
                ; lea     di, VMEM_OFFSET

                lea     si, [bp+WB*11]
                lea     di, DrawBuffer+(DRAW_BUFFER_W+4)*WB
                lea     bx, HexTbl
                mov     cx, REG_CNT
@SetRegs:       
                std
                lodsw                               ; ax = register_value
                cld
                mov     dx, ax
                push    cx
                mov     cx, NIBBLE_REG_CNT
@ConvertToASCII:  
                mov     al, dh
                shr     al, 4
                shl     dx, 4
                xlatb
                mov     ah, REG_VAL_COL_ATTR
                stosw
                loop    @ConvertToASCII

                pop     cx
                add     di, (DRAW_BUFFER_W-3)*WB-WB
                loop    @SetRegs

                push    VRAMSEGMENT
                pop     es
                mov     di, VMEM_OFFSET
                mov     si, offset DrawBuffer

                call    CopyToVMEM

@@End:

                mov     al, 20h
                out     20h, al                     ; EOI (end of interrupt) в контроллер прерываний

                add     sp, 4                       ; skip cs and ip
                pop     es ss ds sp bp di si dx cx bx ax
                iret

UpdIRQ0         endp
;--------------------------------------------------------------------------


;--------------------------------------------------------------------------
; Update IRQ 1
;--------------------------------------------------------------------------
UpdIRQ1         proc

                push    ax bx cx dx di si es ds

                push    cs
                pop     ds

                in      al, 60h
                cmp     al, 02h                     ; scan code of '!'
                je      @@Trigger

                pop     ds es si di dx cx bx ax
                jmp     cs:[OldIRQ9Vec]

@@Trigger:      not     ShowInterface

                mov     cx, ShowInterface
                cmp     cx, 0
                jne     @@EOI
                push    cs
                pop     ds
                push    VRAMSEGMENT
                pop     es
                mov     si, offset SavedBuffer
                mov     di, VMEM_OFFSET
                call    CopyToVMEM

@@EOI:          in      al, 61h
                or      al, 80h                     ; выставляем старший бит порта
                out     61h, al
                and     al, not 80h
                out     61h, al                     ; "мигнули" старшим битом

                mov     al, 20h
                out     20h, al                     ; EOI (end of interrupt) в контроллер прерываний

                pop     ds es si di dx cx bx ax
                iret

UpdIRQ1         endp
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; Draw border to draw buffer
; Entry: ES:DI --> top-left corner of buffer 
;        DS:SI --> arr[9] of symbols
;        AH      = color attrib
;        BX      = width
;        DX      = height
; Destr: CX
;--------------------------------------------------------------------------

RectBorder      proc

                cld
                lodsb
                stosw

                lodsb
                lea     cx, [bx-2]
                rep     stosw

                lodsb
                stosw
                add     di, (DRAW_BUFFER_W-1)*WB

                lodsb
                mov     cx, dx
                sub     cx, 2
@@VertRight:    mov     es:[di], ax
                add     di, DRAW_BUFFER_W*WB
                loop    @@VertRight
                

                lodsb

                std
                stosw
                cld

                lodsb
                lea     cx, [bx-2]
                std
                rep     stosw
                cld

                lodsb
                std
                stosw
                cld
                sub     di, (DRAW_BUFFER_W-1)*WB

                lodsb
                mov     cx, dx
                sub     cx, 2
@@VertLeft:     mov     es:[di], ax
                sub     di, DRAW_BUFFER_W*WB
                loop    @@VertLeft
                
                ret

RectBorder      endp
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; Copy 2D buffer to VMEM 
; Entry: DS:SI --> buffer
;        ES:DI --> vmem top-left corner
;        
; Destr: AX, BX, CX
;--------------------------------------------------------------------------
CopyToVMEM      proc

                mov     bx, DRAW_BUFFER_W
                mov     cx, DRAW_BUFFER_H*DRAW_BUFFER_W

@@CpLoop:       lodsw 
                stosw
                dec     bx

                cmp     bx, 0
                je      @@NewLine
                jmp     @@CpLoopEnd

@@NewLine:      add     di, (SCR_W-DRAW_BUFFER_W)*WB
                mov     bx, DRAW_BUFFER_W

@@CpLoopEnd:    loop    @@CpLoop

                ret

CopyToVMEM      endp
;--------------------------------------------------------------------------

;--------------------------------------------------------------------------
; Load register names to buffer 
; Entry: DS:SI --> reg name table
;        ES:DI --> buffer 
; Destr: AX, BX, CX
;--------------------------------------------------------------------------
LoadRegNm       proc

                mov     bx, REG_NM_LEN
                mov     cx, REG_NM_LEN*REG_CNT
                mov     ah, REG_NM_COL_ATTR

@@CpLoop:       lodsb 
                stosw
                dec     bx

                cmp     bx, 0
                je      @@NewLine
                jmp     @@CpLoopEnd

@@NewLine:      add     di, (DRAW_BUFFER_W-REG_NM_LEN)*WB
                mov     bx, REG_NM_LEN                

@@CpLoopEnd:    loop    @@CpLoop

                ret

LoadRegNm       endp
;--------------------------------------------------------------------------

OldIRQ9Vec              dd 0 

ShowInterface           dw 0

HexTbl                  db '0123456789ABCDEF'

REG_VAL_COL_ATTR        equ 4eh

RegNmTbl                db 'ax bx cx dx si di bp sp ds ss es cs ip '

REG_NM_LEN              equ 3

REG_CNT                 equ 13

REG_NM_COL_ATTR         equ 4eh

BorderTbl               db '#-#|#-#|'

NIBBLE_REG_CNT          equ 4

DRAW_BUFFER_W           equ REG_NM_LEN+NIBBLE_REG_CNT+2

DRAW_BUFFER_H           equ REG_CNT + 2

DRAW_BUFFER_LEN         equ DRAW_BUFFER_W*DRAW_BUFFER_H

VMEM_OFFSET             equ SCR_W*(SCR_H/2)*WB + (SCR_W/2)*WB - (DRAW_BUFFER_H/2)*SCR_W*WB - (DRAW_BUFFER_W/2)*WB

DrawBuffer              dd DRAW_BUFFER_LEN dup(?)

SavedBuffer             dd DRAW_BUFFER_LEN dup(00h)

EOP:            

end                     Start


