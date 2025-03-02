.model tiny ; local @@
            ; equ - define 
            ; ������ ������� ������� 
.code
org 100h

Start:
        call DrawTopBottom    ; ������ ������� �������
        call DrawMiddle       ; ������ ������� �����
        call DrawMiddle       ; ������ ��� ���� ������� �����
        call DrawMiddle       ; ������ ��������� ������� �����
        call DrawTopBottom    ; ������ ������ �������

        mov ax, 4C00h
        int 21h

;--------------------------------------------------
; Draw a line of 15 heart symbols (?)
; Entry:     AH     - 02h (������� ������ �������)
;            DL     - ������ ��� ������ (3 ��� '?')
;            CX     - ���������� �������� (15)
; Exit:      None
; Destr:     CX, DL
;--------------------------------------------------
DrawTopBottom proc
        mov ah, 02h       ; ������� ������ �������
        mov cx, 15        ; (������ �����)
DrawLoop:
        mov dl, 3         ; ������ ��������
        int 21h           ; ������� ������
        loop DrawLoop     ; ��������� 15 ���

        mov ah, 02h
        mov dl, 0Dh       ; ������� �������
        int 21h
        mov dl, 0Ah       ; ������� ������
        int 21h

        ret
DrawTopBottom endp

;--------------------------------------------------
; Draw a line with heart symbols (?) at the start and end, and spaces in between
; Entry:     AH     - 02h (������� ������ �������)
;            DL     - ������ ��� ������ (3 ��� '?' ��� ' ' ��� �������)
;            CX     - ���������� �������� (13)
; Exit:      None
; Destr:     CX, DL
--------------------------------------------------
DrawMiddle proc
    mov ah, 02h       ; ������� ������ �������

    mov dl, 3         ; ������ ��������
    int 21h           ; ������� ������

    mov cx, 13        ; ���������� ��������
SpaceLoop:
    mov dl, ' '      
    int 21h           
    loop SpaceLoop    ; ��������� 13 ���

    mov dl, 3         
    int 21h           

    mov ah, 02h
    mov dl, 0Dh      
    int 21h
    mov dl, 0Ah       
    int 21h

    ret
DrawMiddle endp ; nop !!!! 99 - hex
                ; local

end Start