    DOSSEG
    .MODEL SMALL
    .STACK 32
    .DATA
encoded     DB  80 DUP(0)
temp        DB  '0x', 160 DUP(0)
encrypted   DB  80 DUP(0)
fileHandler DW  ?
filename    DB  'in/in.txt', 0          ; Trebuie sa existe acest fisier 'in/in.txt'!
outfile     DB  'out/out.txt', 0        ; Trebuie sa existe acest director 'out'!
message     DB  80 DUP(0)
msglen      DW  ?
padding     DW  0
iterations  DW  0 
x           DW  102
x0          DD  102
a           DW  16;116
b           DW  78;70 
code_table  DB  'Bqmgp86CPe9DfNz7R1wjHIMZKGcYXiFtSU2ovJOhW4ly5EkrqsnAxubTV03a=L/d'
byte_to_encode DW 0
iterations_encoded DW 0; numara caractere cod 
prenume     DB 'Razvan-Andrei$'
nume        DB 'Leanca$'

    .CODE
START:
    MOV     AX, @DATA
    MOV     DS, AX
    
    PUSH OFFSET a; trimit ca parametru adresa prenumelui si a lui a
    PUSH OFFSET prenume
    CALL COMPUTE_ASCII_SUM

    PUSH OFFSET b
    PUSH OFFSET nume
    CALL COMPUTE_ASCII_SUM

    CALL    FILE_INPUT                  ; NU MODIFICATI!
    
    CALL    SEED                        ; TODO - Trebuie implementata

    CALL    ENCRYPT                     ; TODO - Trebuie implementata
    
    CALL    ENCODE                      ; TODO - Trebuie implementata
    
    CALL    ADD_PADDING
                                        ; Mai jos se regaseste partea de
                                        ; afisare pe baza valorilor care se
                                        ; afla in variabilele x0, a, b, respectiv
                                        ; in sirurile message si encoded.
                                        ; NU MODIFICATI!
    MOV     AH, 3CH                     ; BIOS Int - Open file
    MOV     CX, 0
    MOV     AL, 1                       ; AL - Access mode ( Write - 1 )
    MOV     DX, OFFSET outfile          ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    CALL    WRITE                       ; NU MODIFICATI!

    MOV     AH, 4CH                     ; Bios Int - Terminate with return code
    MOV     AL, 0                       ; AL - Return code
    INT     21H
FILE_INPUT:
    MOV     AH, 3DH                     ; BIOS Int - Open file
    MOV     AL, 0                       ; AL - Access mode ( Read - 0 )
    MOV     DX, OFFSET filename         ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    MOV     AH, 3FH                     ; BIOD Int - Read from file or device
    MOV     BX, [fileHandler]           ; BX - File handler
    MOV     CX, 80                      ; CX - Number of bytes to read
    MOV     DX, OFFSET message          ; DX - Data buffer
    INT     21H
    MOV     [msglen], AX                ; Return: AX - number of read bytes

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H

    RET
SEED:
    MOV     AH, 2CH                     ; BIOS Int - Get System Time
    INT     21H
    PUSH DX; salvez DX pe stiva
    MOV BX, 30
    MOV AH, 00h
    MOV AL, CH;
    MUL BX;
    MOV BX, 255;
    DIV BX;
    PUSH DX; salvez ch * 30 mod 255 pe stiva
    MOV DX, 0000h;
    MOV AH, 00h;
    MOV AL, CL;
    MOV BX, 60;
    MUL BX;
    MOV BX, 255;
    DIV BX;
    POP AX; scot ch * 30 mod 255 si adun cu cl * 60 mod 255
    ADD DX, AX;
    XCHG DX, AX;
    MOV DX, 0000h;
    MOV BX, 255;
    DIV BX;
    XCHG DX, AX;
    MOV DX, 0000h
    POP CX; scot DX-ul salvat mai sus pe CX;
    MOV DL, CH;
    ADD AX, DX;
    MOV BX, 100;
    MUL BX;
    MOV BX, 255;
    DIV BX;
    
    XCHG DX, AX;
    MOV DX, 0000h;
    MOV CH, 00h;
    ADD AX, CX;
    MOV BX, 255;
    DIV BX;
    MOV SI, OFFSET x0;
    MOV [SI], DX;
    MOV SI, OFFSET x;
    MOV [SI], DX;
    RET
ENCRYPT:
    MOV     CX, [msglen]
    ;MOV     SI, OFFSET message
    main_loop:   

    MOV SI, OFFSET x                                     ; TODO3: Completati subrutina ENCRYPT
    MOV AL, [SI]
    MOV SI, OFFSET message
    MOV BX, [iterations]
    XOR AL, BYTE PTR ([SI + BX])                                         ; astfel incat in cadrul buclei sa fie
    MOV SI, OFFSET temp                                        ; XOR-at elementul curent din sirul de
    MOV byte ptr [SI + BX + 2], AL    
    
    ;pentru encrypted
    MOV SI, OFFSET encrypted
    MOV byte ptr [SI + BX], AL
                                    
    CALL RAND
    INC iterations
    LOOP main_loop                                        ; sirul generat, iar mai apoi sa fie generat                          ; si termenul urmator
    RET
RAND:
    ;verific daca CX e 0 ca sa nu mai apelez RAND sa afiseze corect x-ul in output
    CMP CX, 0001h
    JE SKIP_RAND
    MOV     AX, [x]
    MOV SI, OFFSET a                                        ; TODO2: Completati subrutina RAND, astfel incat
    MOV BX, [SI]                                        ; in cadrul acesteia va fi calculat termenul
    MUL BX
    MOV SI, OFFSET b                                       ; de rang n pe baza coeficientilor a, b si a 
    ADD AX, [SI]               
    MOV BX, 255            
    DIV BX           ; termenului de rang inferior (n-1) si salvat
    MOV SI, OFFSET x  
    MOV [SI], DX        
    ;MOV SI, OFFSET x0
    ;MOV [SI], DX
    SKIP_RAND:                              ; in cadrul variabilei 'x'
    RET
ENCODE:
    MOV SI, OFFSET iterations
    MOV [SI], 0000h
    MOV AX, [msglen]
    MOV BX, 3
    DIV BL
    CMP AH, 00h
    MOV CH, 00h;
    JE SKIP_ADDING_PADDING
    INC AL
    SKIP_ADDING_PADDING:
    ADD CL, AL;

    main_loop_encode:
    MOV SI, OFFSET byte_to_encode
    MOV [SI], 0

    PUSH CX;
    MOV SI, OFFSET temp
    MOV BX, [iterations]
    ; aduc din memorie ce am nevoie
    MOV CH, BYTE PTR [SI + 2 + BX]
    MOV CL, BYTE PTR [SI + 3 + BX] ; 2 de la x0 din variabila temp
    MOV DH, BYTE PTR [SI + 4 + BX] ;
    MOV DL, 00h
    PUSH DX; salvez pe stiva
    PUSH CX; cei trei octeti

    ; Folosesc cate o procedura pentru fiecare grup de 6 biti
    CALL FIRST_6GROUP
    
    CALL WRITE_IN_ENCODE
    
    CALL SECOND_6GROUP
    
    CALL WRITE_IN_ENCODE

    CALL THIRD_6GROUP

    CALL WRITE_IN_ENCODE

    CALL FOURTH_6GROUP

    CALL WRITE_IN_ENCODE

    ADD [iterations], 3; din cerinta
    ADD [iterations_encoded], 4;
    POP CX;
    LOOP main_loop_encode                                 ; in cadrul variabilei encoded
    RET

WRITE_IN_ENCODE:
    MOV SI, OFFSET code_table;
    ADD SI, DX;

    MOV CH, 00h;
    MOV CL, BYTE PTR [SI];

    MOV SI, OFFSET encoded
    ADD SI, [iterations_encoded]
    ADD SI, [byte_to_encode]
    MOV [SI], CL
    INC byte_to_encode
    RET

WRITE_HEX:
    MOV     DI, OFFSET temp + 2
    XOR     DX, DX
DUMP:
    MOV     DL, [SI]
    PUSH    CX
    MOV     CL, 4

    ROR     DX, CL
    
    CMP     DL, 0ah
    JB      print_digit1

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     next_digit

print_digit1:  
    OR      DL, 30h
    MOV     byte ptr [DI] ,DL
next_digit:
    INC     DI
    MOV     CL, 12
    SHR     DX, CL
    CMP     DL, 0ah
    JB      print_digit2

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     AGAIN

print_digit2:    
    OR      DL, 30h
    MOV     byte ptr [DI], DL
AGAIN:
    INC     DI
    INC     SI
    POP     CX
    LOOP    dump
    
    MOV     byte ptr [DI], 10
    RET
WRITE:
    MOV     SI, OFFSET x0
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21h

    MOV     SI, OFFSET a
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET b
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET x
    MOV     CX, 1
    CALL    WRITE_HEX    
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    ;MOV     SI, OFFSET message
    MOV     SI, OFFSET encrypted
    MOV     CX, [msglen]
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, [msglen]
    ADD     CX, [msglen]
    ADD     CX, 3
    INT     21h

    MOV     AX, [iterations_encoded]
    MOV     BX, 4
    ;MUL     BX
    MOV     CX, AX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET encoded
    INT     21H

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H
    RET

FIRST_6GROUP:
    ;Masca pentru primii 6 biti
    MOV BX, 64512; 1111 1100
    AND BH, CH;
    SAR BH, 2; pentru a evita ca shiftarea sa se faca cu umplere de unu, facem un AND cu 3FFF
    MOV DL, 3Fh;
    AND DL, BH;
    MOV DH, 00h;
    RET
SECOND_6GROUP:
;MASCA PENTRU CEI MAI NESEMNIFICATIVI 6 BITI
    MOV DX, 03F0h
    POP BX; scot adresa de return
    POP CX; scot de pe stiva primii doi octeti salvati
    AND DX, CX
    PUSH CX
    SAR DX, 4; mut cei doi biti la stanga, urmand sa adun urmatorii 4 biti din octetul nr 3
    PUSH BX; introduc inapoi adresa de return
    RET
THIRD_6GROUP:
 ;luam ultimii 4 biti de pe al doilea octet
    MOV BX, 000Fh; masca
    POP AX; scot adresa de return
    POP CX;
    AND BX, CX;
    MOV DL, BL; salvez rezultatul in DX temporar
    SHL DL, 2; shiftez 
    POP CX; scot si al treilea octet
    MOV BX, 49152; masca pentru primii doi biti
    AND BX, CX;
    SHR BH, 6;
    ADD DL, BH; creez al treilea octet in DL
    MOV DH, 00h;
    PUSH CX;
    PUSH AX; introduc inapoi adresa de return
    RET
FOURTH_6GROUP:
    ;AL PATRULEA OCTET
    POP AX; scot adresa de return
    POP CX;
    MOV DX, 3F00h; masca
    AND DX, CX
    SAR DX, 8
    PUSH AX; introduc inapoi adresa de return
    RET
ADD_PADDING:
    MOV AX, [msglen]
    MOV BX, 3
    DIV BL
    CMP AH, 00h
    JE SKIP
    MOV CH, 00h;
    MOV CL, 03h
    SUB CL, AH; numarul de octeti de padding sunt in CX
    MOV [padding], CX
    MOV SI, OFFSET encoded
    MOV BX, [iterations_encoded]
    SUB BX, CX
    CMP CX, 0000h
    JE SKIP
    padding_loop:
    MOV [SI + BX], 43
    INC BX
    LOOP padding_loop
SKIP:
    RET

COMPUTE_ASCII_SUM:
POP CX; salvez temporar adresa din call
POP SI; salvez offset sir
POP DI; salvez destinatia
PUSH CX; inserez inapoi CX pe stiva urmand sa fie folosit de RET
MOV AL, [SI]; prima litera
MOV AH, 00h
MOV DL, 255
MOV DH, 00h
LOOP_CALCULATE:
MOV CL, [SI + 1]; iterez literele
MOV CH, 00h
CMP CL, '$'
JE END_LOOP_CALCULATE
ADD AX, CX
DIV DL
XCHG AH, AL
MOV AH, 00h
INC SI
JMP LOOP_CALCULATE
END_LOOP_CALCULATE:
MOV [DI], AX
RET

    END START

