.model tiny ; local @@
            ; equ - define 
            ; писать большие коменты 
.code
org 100h

Start:
        call DrawTopBottom    ; Рисуем верхнюю границу
        call DrawMiddle       ; Рисуем среднюю часть
        call DrawMiddle       ; Рисуем еще одну среднюю часть
        call DrawMiddle       ; Рисуем последнюю среднюю часть
        call DrawTopBottom    ; Рисуем нижнюю границу

        mov ax, 4C00h
        int 21h

;--------------------------------------------------
; Draw a line of 15 heart symbols (?)
; Entry:     AH     - 02h (функция вывода символа)
;            DL     - символ для вывода (3 для '?')
;            CX     - количество символов (15)
; Exit:      None
; Destr:     CX, DL
;--------------------------------------------------
DrawTopBottom proc
        mov ah, 02h       ; Функция вывода символа
        mov cx, 15        ; (ширина рамки)
DrawLoop:
        mov dl, 3         ; Символ сердечка
        int 21h           ; Выводим символ
        loop DrawLoop     ; Повторяем 15 раз

        mov ah, 02h
        mov dl, 0Dh       ; Возврат каретки
        int 21h
        mov dl, 0Ah       ; Перевод строки
        int 21h

        ret
DrawTopBottom endp

;--------------------------------------------------
; Draw a line with heart symbols (?) at the start and end, and spaces in between
; Entry:     AH     - 02h (функция вывода символа)
;            DL     - символ для вывода (3 для '?' или ' ' для пробела)
;            CX     - количество пробелов (13)
; Exit:      None
; Destr:     CX, DL
--------------------------------------------------
DrawMiddle proc
    mov ah, 02h       ; Функция вывода символа

    mov dl, 3         ; Символ сердечка
    int 21h           ; Выводим символ

    mov cx, 13        ; Количество пробелов
SpaceLoop:
    mov dl, ' '      
    int 21h           
    loop SpaceLoop    ; Повторяем 13 раз

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