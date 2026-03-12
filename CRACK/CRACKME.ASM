.286
.model tiny
locals @@

.code
org 100h

;--------------------------------------------------------------------
DISP_STR            MACRO str_addr
                    mov     ah, 09h
                    lea     dx, str_addr
                    int     21h
                    ENDM
;--------------------------------------------------------------------

;--------------------------------------------------------------------
DISP_CHR            MACRO chr
                    mov     ah, 02h
                    mov     dl, chr
                    int     21h
                    ENDM
;--------------------------------------------------------------------

;--------------------------------------------------------------------
INP_STR             MACRO str_addr
                    mov     ah, 0ah
                    lea     dx, str_addr
                    int     21h
                    ENDM
;--------------------------------------------------------------------

;--------------------------------------------------------------------
CMP_STR             MACRO strlen, str1_addr, str2_addr
                    mov     cx, strlen
                    lea     si, str1_addr
                    lea     di, str2_addr
                    repe cmpsb
                    ENDM
;--------------------------------------------------------------------

;--------------------------------------------------------------------
EXIT_WITH_CODE      MACRO exit_code
                    mov     ah, 4ch
                    mov     al, exit_code
                    int     21h
                    ENDM
;--------------------------------------------------------------------


Start:              DISP_STR StrGreet

                    DISP_STR StrEnterPasswd

                    INP_STR StrPasswdInp

                    push    ds
                    pop     es
                    lea     si, StrPasswdInp+2
                    lea     di, PasswdHash
                    call    Hash

                    CMP_STR HASH_LEN, PasswdHash, CorrectPasswdHash

                    DISP_CHR CARRIAGE_RET
                    DISP_CHR LINE_FEED

                    je      Correct

inf:                jmp inf

Incorrent:          DISP_STR StrIncorrect
                    jmp     ProgramEnd

Correct:            DISP_STR StrCorrect


ProgramEnd:         EXIT_WITH_CODE 00h 

;--------------------------------------------------------------------
; Hash <HASH_LEN> bytes
; Entry: DS:SI --> data[HASH_LEN]
; Exit:  ES:DI --> hash[HASH_LEN]
; Destr: AX, CX
;--------------------------------------------------------------------
Hash                PROC
                    
                    mov     cx, HASH_LEN

@@lp:               lodsb 
                    sal     ax, 1
                    stosb
                    loop    @@lp
                    
                    ret

Hash                ENDP
;--------------------------------------------------------------------

CARRIAGE_RET        equ 0dh
LINE_FEED           equ 0ah
CRLF                equ CARRIAGE_RET, LINE_FEED
STR_TRMT            equ '$'
PASSWD_LEN          equ 4
HASH_LEN            equ 4

StrGreet            db ' _    _          _____ _  ____  __ ______ ', CRLF
                    db '| |  | |   /\   / ____| |/ /  \/  |  ____|', CRLF
                    db '| |__| |  /  \ | |    | | /| \  / | |__   ', CRLF
                    db '|  __  | / /\ \| |    |  < | |\/| |  __|  ', CRLF
                    db '| |  | |/ ____ \ |____| . \| |  | | |____ ', CRLF
                    db '|_|  |_/_/    \_\_____|_|\_\_|  |_|______|', CRLF
                    db STR_TRMT

StrCorrect          db 'Access granted', STR_TRMT

StrIncorrect        db 'Access denied', STR_TRMT

StrEnterPasswd      db 'Enter password: ', STR_TRMT

StrPasswdInp        db 254, PASSWD_LEN+2 dup(?) ; | <max> | ... | --> | <max> | <len> | ... | <terminator> | 

CorrectPasswdHash   db 0e0h, 0c2h, 0e6h, 0eeh

PasswdHash          db HASH_LEN dup(?)

end Start
