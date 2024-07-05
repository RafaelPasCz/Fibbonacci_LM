; compilar:  nasm -f elf64 fibbo.asm ; ld fibbo.o -o fibbo.x
; executar:  ./fibbo.x
; verificar arquivo: xxd -b 'fib(n).bin'

%define maxChars    10

section .data
    strOla : db "Digite o n-essimo numero de fib(1 - 47): "
    strOlaL: equ $ - strOla

    strErro : dq "Este sistema não determina este numero"
    strErroL: equ $ - strErro

    strLF  : db 10 ; quebra de linha
    strLFL : equ 1

    arqv   : db "fib(nn).bin", 0

    strsuc : dq "Seu resultado foi salvo no arquivo."
    strsucL: equ $ - strsuc

    strpres : dq "Pressione enter para sair."
    strpresL: equ $ - strpres

section .bss
    strNum  : resb maxChars
    strNumL : resd 1
    num1    : resd 1
    num2    : resd 1
    fileH   : resd 1
    buffer  : resb 32

section .text
    global _start

_start:
    ; imprime a mensagem de entrada.
    mov rax, 1
    mov rdi, 1
    lea rsi, [strOla]
    mov edx, strOlaL
    syscall

leitura:
    ; le a entrada di teclado
    mov dword [strNumL], maxChars
    mov rax, 0
    mov rdi, 1
    lea rsi, [strNum]
    mov edx, [strNumL]
    syscall                         ; manda a quantidade de char lidos para o eax

    cmp eax, 3                      ; ve se foram no maximo 3 char lidos ( dezena//unidade//enter ), caso seja mais jump para erro
    jg erro


nome:
    cmp eax, 2
    jg nome1

    mov al, byte [strNum]
    mov byte [arqv + 4], "0"
    mov byte [arqv + 5], al
    jmp trans

nome1:

    mov al, byte [strNum]
    mov byte [arqv + 4], al
    mov al, byte [strNum + 1]
    mov byte [arqv + 5], al

trans:
    mov r10, 1                      ; bota 1 no 10 pra ser usado na aritmetica
    mov r8b, byte [strNum]          ; recebe o primeiro byte da string digitada
    mov r9b, byte [strNum + r10]    ; recebe o proximo byte (r10 = 1, strNum + 1 = prox byte)
    sub r8, 0x30                    ; transforma ele de ASCII para inteiro
    mov al, byte [strNum]           ; é necessario para multiplicação
    sub al, 0x30                    ; transforma em inteiro
    cmp r9, 0xa                     ; se o proximo byte for enter (fim da string)
    je val_ini                      ; jump para o resto do codigo (transformação terminada)
    sub r9, 0x30                    ; se não, transforma de ASCII para inteiro
    mov eax, 10                     ; move 10 para ser multiplicado por eax
    mul r8                          ; multiplica o numero do byte anterior por 10, ja que ele representa a dezena
    add eax, r9d                    ; soma os dois numeros.
    
val_ini:
    mov byte [num1], 1
    mov byte [num2], 1

comp1:
    mov [strNum], eax               ; manda o valor transformado para a string original
    cmp byte [strNum], 0            ; compara se é = 0
    je erro                         ; jump se igual a zero
    cmp byte [strNum], 47           ; compara se for maior que 46 (a partir de 47 da estouro)
    jg erro                         ; jump se maior a 46
    cmp byte [strNum], 1            ; ver se o usuario esta requisitando fibonacci de 1, que não precisa de calculo
    je print                        ; exibe o valor de fibonacci de 1
    cmp byte [strNum], 2            ; mesma coisa
    je print
    mov r15, 3                      ; sera a partir deste numero que começaremos a calcular fib

calculo:
    mov r14d, [num1]                ; salva a variavel em um registrador para o valor 1 não ser perdido
    mov r13d, [num1]                ; manda o valor 1 para um registrador onde vai ser modificada
    add r13d, [num2]                ; soma os 2 numeros anteriores
    mov [num1], r13d                ; manda o valor somado para a variavel
    mov [num2], r14d                ; manda o valor 1 para a variavel 2, que agora é o numero antigo
    cmp r15, [strNum]               ; ve se o valor atual do indice é o desejado de fib(n)
    je print                        ; se sim pula pra print
    inc r15                         ; se não incrementa
    jmp calculo                     ; e volta para calculo para refazer o processo

    
erro:
    ; imprime a mensagem de erro generica.
    mov rax, 1 
    mov rdi, 1
    lea rsi, [strErro]
    mov edx, strErroL
    syscall

    ; pula linha pra n ficar feio
    mov rax, 1 
    mov rdi, 1
    lea rsi, [strLF]
    mov edx, strLFL
    syscall
    jmp limpabuffer

print:
    ; abrir arquivo
    mov rax, 2
    lea rdi, [arqv] 
    mov rsi, 0o102  
    mov rdx, 0o644  
    syscall

    mov [fileH], rax                ; move o caminho do arquivo para a variavel

    ; eescrever no arquivo
    mov rax, 1
    mov rdi, [fileH]
    lea rsi, [num1]
    mov rdx, 4        
    syscall

    ; fechar arquivo
    mov rax, 3  
    mov rdi, [fileH]
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [strsuc]
    mov edx, strsucL
    syscall

    mov rax, 1 
    mov rdi, 1
    lea rsi, [strLF]
    mov edx, strLFL
    syscall


    mov rax, 1
    mov rdi, 1
    lea rsi, [strpres]
    mov edx, strpresL
    syscall



limpabuffer:
    ; lê 32 byte (32 char) do buffer
    mov rax, 0
    mov rdi, 0
    lea rsi, buffer
    mov edx, 32
    syscall

    mov r9, 0                       ; inicializa o contador de caracteres lidos
proxim:
    mov r8b, byte [buffer + r9]     ; caracter atual
    cmp r8b, 10                     ; verifica se é Enter
    je fim                          ; se for Enter, termina a entrada
    cmp r8b, 0                      ; verifica se é nulo (fim da string)
    je fim                          ; se for nulo, termina a entrada
    inc r9                          ; incrementa
    cmp r9, 32                      ; compara se ainda não chegou no final
    jl proxim                       ; caso não tenha chegado
    cmp r9, 32                      ; compara se ja chegou no final
    je limpabuffer                  ; caso tenha chegado, volta no lipabuffer para pegar mais 32 char
    
fim:
    mov byte [buffer + r9], 0       ; define o último caractere lido como nulo
    mov rax, 60
    mov rdi, 0
    syscall
