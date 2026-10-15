
; ==================================================
; PROBLEM 1: NAME, AGE, AND GENDER GREETING
; NASM 32-bit Assembly - Linux
; ==================================================

section .data
    namePrompt   db "What is your name? ", 0
    agePrompt    db "How old are you? ", 0
    genderPrompt db "What is your gender? ", 0

    helloMsg     db "Hello ", 0
    ageMsg       db "You are ", 0
    yearsMsg     db " years old", 10, 0

    maleMsg      db "Hello", 10, 0
    femaleMsg    db "World", 10, 0
    invalidMsg   db "INVALID", 10, 0
    invalidAge   db "INVALID AGE", 10, 0
    invalidName  db "INVALID NAME", 10, 0

    newline      db 10, 0

section .bss
    nameBuffer   resb 128
    ageBuffer    resb 32
    genderBuffer resb 32
    inputChar    resb 1
    overflowFlag resb 1
    ageValue     resd 1
    genderLength resd 1

section .text
    global _start

; ==================================================
; MAIN PROGRAM
; ==================================================

_start:
    ; Ask for full name
    mov ecx, namePrompt
    call print_string

    mov edi, nameBuffer
    mov ebp, 127
    call read_line

    cmp eax, -1
    je bad_name

    cmp eax, 0
    je bad_name

    ; Ask for age
    mov ecx, agePrompt
    call print_string

    mov edi, ageBuffer
    mov ebp, 31
    call read_line

    cmp eax, -1
    je bad_age

    ; Convert and validate age
    mov esi, ageBuffer
    call ascii_to_int

    jc bad_age

    mov [ageValue], eax

    ; Ask for gender
    mov ecx, genderPrompt
    call print_string

    mov edi, genderBuffer
    mov ebp, 31
    call read_line

    mov [genderLength], eax

    ; Display name
    mov ecx, helloMsg
    call print_string

    mov ecx, nameBuffer
    call print_string

    mov ecx, newline
    call print_string

    ; Display age
    mov ecx, ageMsg
    call print_string

    mov ecx, ageBuffer
    call print_string

    mov ecx, yearsMsg
    call print_string

    ; Validate gender input length
    cmp dword [genderLength], 1
    jne invalid_gender

    ; Check gender
    mov al, [genderBuffer]

    cmp al, 'M'
    je male

    cmp al, 'm'
    je male

    cmp al, 'F'
    je female

    cmp al, 'f'
    je female

    jmp invalid_gender

male:
    mov ecx, maleMsg
    call print_string
    jmp exit_program

female:
    mov ecx, femaleMsg
    call print_string
    jmp exit_program

invalid_gender:
    mov ecx, invalidMsg
    call print_string
    jmp exit_program

bad_age:
    mov ecx, invalidAge
    call print_string
    jmp exit_program

bad_name:
    mov ecx, invalidName
    call print_string
    jmp exit_program

; ==================================================
; PROCEDURE: PRINT STRING
; Input: ECX = address of null-terminated string
; ==================================================

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

; ==================================================
; PROCEDURE: READ LINE
; Input: EDI = buffer, EBP = maximum length
; Output: EAX = length, -1 if too long
; ==================================================

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

; ==================================================
; PROCEDURE: ASCII TO INTEGER
; Input: ESI = numeric string
; Output: EAX = integer
; Carry flag set if invalid
; ==================================================

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

; ==================================================
; EXIT PROGRAM
; ==================================================

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80
