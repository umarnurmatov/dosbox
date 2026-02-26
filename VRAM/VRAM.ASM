.model tiny

.data

.code
org 100h

VRAMSEGMENT	                equ 0b800h
ARGCNT_ADDR	                equ 80h
CMDARG_ADDR	                equ 81h
DEFAULT_STR_COLATTRIB	    equ 0eh 
DEFAULT_BORDR_COLATTRIB	    equ 1eh 
SCREENH		                equ 19h
SCREENW		                equ 2*50h
B_OFFSET                    equ 4h
CTRL_CHR                    equ 2fh
NL_CHR                      equ '$'
DEFAULT_BORDR_CHR           equ '#'

locals @@

Start:		    call Main 

Exit:           mov ax, 004ch
                int 21h

;-------------------------------------
; Main func
;-------------------------------------
Main		    proc

                push bp
                mov bp, sp

                mov si, ARGCNT_ADDR		
                mov byte ptr cl, [si]       ; cx = str_len

                jcxz Exit

                push CTRL_CHR cx CMDARG_ADDR
                call StrChr
                add sp,6

                mov byte ptr al, [si]
                cmp ax, cx                  
                jne @@else                  ; if(ax != str_len)
                push DEFAULT_BORDR_CHR      ; [bp-4] = default border char
                dec cx                      ; cx = actual string length
                                            ; excluding whitespace
                jmp @@if_end

@@else:         
                mov di, CMDARG_ADDR         ; control char present
                add di, cx                  
                mov byte ptr al, [di]       ; parse control sequence
                push ax                     ; [bp-2] = border char

                sub cx, 3                   ; cx = actual string length
                                            ; excluding whitespaces and control char
@@if_end:        
                add si, 2                   ; si = CMDARG_ADDR + 1 (skip whitespace)
                push si                     ; [bp-4] --> string

                push cx                     ; [bp-6] = string length

                mov ah, NL_CHR              
                call MaxSubstrLen
                push dx                     ; [bp-8] = max line length

                mov cx, [bp-6]              
                mov si, [bp-4]
                call CntChr                 
                push dx                     ; [bp-10] = line count

                mov di, SCREENW*(SCREENH/2) + SCREENW/2
                mov ax, VRAMSEGMENT
                mov es, ax
                mov ah, DEFAULT_STR_COLATTRIB           
                mov dx, [bp-8]
                shr dx, 1h
                sal dx, 1h
                sub di, dx		            ; pox_y -= str_len / 2

                push di                     ; [bp-12] = first str char pos

                mov si, [bp-4]
                mov cx, [bp-6]

                call PrintStr

                mov ax, [bp-2]
                mov cx, [bp-8]
                mov di, [bp-12]

                sub di, B_OFFSET + SCREENW
                add cl, B_OFFSET
                mov ch, [bp-10]
                add ch, 3
                mov ah, DEFAULT_BORDR_COLATTRIB

                push di ax cx

                call RectBorder
                
                add sp,12
                pop bp
                ret
Main            endp

;-------------------------------------



;-------------------------------------
; Find symbol in string
; Entry: stack[0] --> string  
;        stack[2]   = string length
;        stack[4]   = charachter to find
; Exit:  CX         = charachter position
; Assum: ES points to string segment
; Destr: AX, DI
; Notes: Cdecl
;-------------------------------------

StrChr          proc
                
                push bp
                mov bp, sp

                mov word ptr di, [bp+4]
                mov word ptr cx, [bp+6]
                mov byte ptr al, [bp+8]

                cld                         ; clear direction flag

                repne scasb                 ; while(cx--) if(al == es:[di++]) break;
                                            ; cx = len - pos

                mov word ptr ax, [bp+6]
                neg cx
                add cx, ax

                pop bp
                ret
StrChr          endp

;-------------------------------------

;-------------------------------------
; Maximum char-separated substr length
; Entry: DS:SI --> string
;        AH      = separating char
;        CX      = string length
; Exit:  DX      = max substr length
; Destr: DI, SI, CX, BX
;-------------------------------------

MaxSubstrLen    proc

                xor dx, dx
                xor bx, bx

                mov di, si
                add di, cx
                mov ds:[di], ah
                inc cx

@@Strlp:        lodsb 
                cmp ah, al
                je @@CmpSubstrLen
                inc bx
                jmp @@StrlpEnd
@@CmpSubstrLen:
                cmp bx, dx
                ja @@UpdateMaxLen
                jmp @@ResetCnt
@@UpdateMaxLen:
                mov dx, bx
@@ResetCnt:     xor bx, bx
@@StrlpEnd:     loop @@Strlp
                
                ret

MaxSubstrLen    endp

;-------------------------------------


;-------------------------------------
; Count character entrances in string
; Entry: DS:SI --> string
;        AL      = char
;        CX      = string length
; Exit:  DX      = entrances cnt
; Destr: SI, CX, DX
;-------------------------------------

CntChr          proc

                xor dx, dx

@@strlp:        lodsb
                cmp ah, al
                jne @@strlp_end
                inc dx 
@@strlp_end:    loop @@strlp
                
                ret

CntChr          endp

;-------------------------------------


;-------------------------------------
; Print string
; 
; Entry: DS:SI --> string
;        ES:DI --> vram addr
;        CX    =   string length
; Destr: SI, DI, CX
;-------------------------------------

PrintStr        proc
                
                push bp
                mov bp, sp

                push di                     ; [bp-2] = first line chr
                
@@strlp:        mov al, ds:[si]
                cmp al, NL_CHR
                jne @@same_line
                pop di
                add di, SCREENW 
                push di
                jmp @@strlp_end 
@@same_line:    stosw	                    ; es:[di] = ah; ++di
@@strlp_end:    inc si
                dec cl
                jnz @@strlp

                add sp,2
                pop bp
                ret
PrintStr        endp

;-------------------------------------

;-------------------------------------
; Draw rectangular border
; Entry: stack[0] = top left corner
;        stack[2] = char
;        stack[3] = color attribute
;        stack[4] = width
;        stack[5] = height
; Exit:  none
; Assum: ES points to VRAM segment
; Destr: AX, CX, DX, DI
; Note:  Pascal
;-------------------------------------

RectBorder      proc
                
                push bp
                mov bp, sp

                mov word ptr cx, [bp+4]
                mov word ptr ax, [bp+6]
                mov word ptr di, [bp+8] 
                xor ch, ch

                mov byte ptr cl, [bp+5]
                
                call VerticalLine

                mov byte ptr cl, [bp+4]

                call HorizontalLine

                mov byte ptr cl, [bp+5] 
                mov ch, 1h

                call VerticalLine

                mov byte ptr cl, [bp+4]

                call HorizontalLine
                
                pop bp
                ret 6
RectBorder      endp

;-------------------------------------
                
;-------------------------------------
; Ouputs vertical line of given length
;
; Entry: ES:DI = first line point
;        AL    = char
;        AH    = color attribute
;        CL    = length
;        CH    = direction
; Exit:  DI  --> last line point
; Destr: CL, DX
;-------------------------------------

VerticalLine    proc

                cmp ch, 0
                je @@if
                mov dx, -SCREENW
                jmp @@endif
@@if:           mov dx, SCREENW
@@endif:
                
@@loopv:        mov word ptr es:[di], ax  
                add di, dx
                dec cl
                jnz @@loopv

                sub di, dx

                ret
VerticalLine    endp

;-------------------------------------

;-------------------------------------
; Ouputs horizontal line of given length
;
; Entry: ES:DI = first line point
;        AL    = char
;        AH    = color attribute
;        CL    = length
;        CH    = direction
; Exit:  DI  --> last line point
; Destr: CL, DX 
;-------------------------------------

HorizontalLine  proc

                cmp ch, 0
                je @@if
                mov dx, -2h
                jmp @@endif
@@if:           mov dx, 2h
@@endif:
                
@@loopv:        mov word ptr es:[di], ax  
                add di, dx
                dec cl
                jnz @@loopv

                sub di, dx

                ret
HorizontalLine  endp

;-------------------------------------

end Start
