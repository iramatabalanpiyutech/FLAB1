
; ================================================
; PROBLEM 3: STUDENT GRADE EVALUATION
; NASM 32-bit Assembly - Linux
; ================================================

section .data
    promptName db "Enter student name: ", 0
    promptID   db "Enter student ID: ", 0
    promptGrade db "Enter grade: ", 0

    msgName    db "Student Name: ", 0
    msgID      db "Student ID: ", 0
    msgGrade   db "Grade: ", 0
    msgClass   db "Classification: ", 0

    msgExcellent db "Excellent", 10, 0
    msgVeryGood  db "Very Good", 10, 0
    msgGood      db "Good", 10, 0
    msgPassed    db "Passed", 10, 0
    msgFailed    db "Failed", 10, 0
    msgInvalid   db "INVALID GRADE", 10, 0

    msgBadName   db "INVALID NAME", 10, 0
    msgBadID     db "INVALID STUDENT ID", 10, 0
    newline      db 10, 0

section .bss
    nameBuffer   resb 128
    idBuffer     resb 64
    gradeBuffer  resb 32
    inputChar    resb 1
    overflowFlag resb 1
    gradeValue   resd 1
    gradeValid   resb 1

section .text
    global _start

_start:
    ; Read full name
    mov ecx, promptName
    call print_string

    mov edi, nameBuffer
    mov ebp, 127
    call read_line

    cmp eax, 0
    jle bad_name

    ; Read student ID as text
    mov ecx, promptID
    call print_string

    mov edi, idBuffer
    mov ebp, 63
    call read_line

    cmp eax, 0
    jle bad_id

    ; Read grade
    mov ecx, promptGrade
    call print_string

    mov edi, gradeBuffer
    mov ebp, 31
    call read_line

    mov byte [gradeValid], 0

    cmp eax, -1
    je display_details

    ; Convert ASCII grade to integer
    mov esi, gradeBuffer
    call ascii_to_int

    jc display_details

    ; Check maximum grade
    cmp eax, 100
    ja display_details

    mov [gradeValue], eax
    mov byte [gradeValid], 1

display_details:
    ; Display name
    mov ecx, msgName
    call print_string

    mov ecx, nameBuffer
    call print_string

    mov ecx, newline
    call print_string

    ; Display ID
    mov ecx, msgID
    call print_string

    mov ecx, idBuffer
    call print_string

    mov ecx, newline
    call print_string

    ; Display grade
    mov ecx, msgGrade
    call print_string

    mov ecx, gradeBuffer
    call print_string

    mov ecx, newline
    call print_string

    ; Display classification
    mov ecx, msgClass
    call print_string

    cmp byte [gradeValid], 1
    jne invalid_grade

    mov eax, [gradeValue]

    cmp eax, 90
    jae excellent

    cmp eax, 85
    jae very_good

    cmp eax, 80
    jae good

    cmp eax, 75
    jae passed

    jmp failed

excellent:
    mov ecx, msgExcellent
    call print_string
    jmp exit_program

very_good:
    mov ecx, msgVeryGood
    call print_string
    jmp exit_program

good:
    mov ecx, msgGood
    call print_string
    jmp exit_program

passed:
    mov ecx, msgPassed
    call print_string
    jmp exit_program

failed:
    mov ecx, msgFailed
    call print_string
    jmp exit_program

invalid_grade:
    mov ecx, msgInvalid
    call print_string
    jmp exit_program

bad_name:
    mov ecx, msgBadName
    call print_string
    jmp exit_program

bad_id:
    mov ecx, msgBadID
    call print_string
    jmp exit_program

; ================================================
; PRINT STRING PROCEDURE
; ECX = address of string
; ================================================

print_string:
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov esi, ecx
    xor edx, edx

count_chars:
    cmp byte [esi + edx], 0
    je print_now
    inc edx
    jmp count_chars

print_now:
    mov eax, 4
    mov ebx, 1
    int 0x80

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; ================================================
; READ LINE PROCEDURE
; EDI = buffer, EBP = max characters
; EAX = length, or -1 if too long
; ================================================

read_line:
    push ebx
    push ecx
    push edx
    push esi

    xor esi, esi
    mov byte [overflowFlag], 0

read_next:
    mov eax, 3
    mov ebx, 0
    mov ecx, inputChar
    mov edx, 1
    int 0x80

    cmp eax, 1
    jne read_done

    mov al, [inputChar]

    cmp al, 10
    je read_done

    cmp al, 13
    je read_next

    cmp esi, ebp
    jae mark_overflow

    mov [edi + esi], al
    inc esi
    jmp read_next

mark_overflow:
    mov byte [overflowFlag], 1
    jmp read_next

read_done:
    mov byte [edi + esi], 0
    mov eax, esi

    cmp byte [overflowFlag], 0
    je read_return

    mov eax, -1

read_return:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ================================================
; ASCII TO INTEGER PROCEDURE
; ESI = numeric string
; EAX = converted value
; CF = 1 for invalid input
; ================================================

ascii_to_int:
    push ebx
    push ecx
    push edx
    push esi

    xor eax, eax
    mov ebx, 10

    cmp byte [esi], 0
    je convert_invalid

convert_loop:
    movzx edx, byte [esi]

    cmp dl, 0
    je convert_done

    cmp dl, '0'
    jb convert_invalid

    cmp dl, '9'
    ja convert_invalid

    sub edx, '0'
    push edx

    mul ebx
    pop ecx

    jc convert_invalid

    add eax, ecx
    jc convert_invalid

    inc esi
    jmp convert_loop

convert_done:
    clc
    jmp convert_return

convert_invalid:
    stc

convert_return:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; ================================================
; EXIT PROGRAM
; ================================================

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80
