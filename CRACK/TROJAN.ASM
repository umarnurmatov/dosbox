.286
.model tiny
locals @@

.code
org 100h

Start:              push    0
                    pop     es
                    mov     bx, 4*21h

                    mov     ax, es:[bx]
                    mov     word ptr OldIntVec_21, ax 
                    mov     ax, es:[bx+2]
                    mov     word ptr OldIntVec_21+2, ax

                    cli
                    mov     es:[bx], offset NewInt21
                    mov     ax, cs
                    mov     es:[bx+2], ax
                    sti
                    
                    mov     ax, 3100h
                    lea     dx, EOP
                    shr     dx, 4
                    inc     dx
                    int     21h



;--------------------------------------------------------------------
; New int 21h handler
;--------------------------------------------------------------------

NewInt21            PROC

                    cmp     ah, 2h
                    je      @@ChangeZF

@@IntChain:         jmp     cs:[OldIntVec_21]

@@ChangeZF:         push    ax bx bp

                    mov     bp, sp

                    mov     ax, ss:[bp+10]
                    mov     bx, 1
                    sal     bx, 6
                    or      ax, bx
                    mov     ss:[bp+10], ax

                    pop     bp bx ax
                    iret

NewInt21            ENDP

;--------------------------------------------------------------------


OldIntVec_21        dd 0

EOP:

end Start
