                .PROJECT HEX
                .TAPE microsha-rkm ; ФОРМАТ ЛЕНТЫ RKM
;*******************************************************************************
; This is a code for a hexadecimal calculator program running on a Soviet-era 
; computer system "Microsha". 
;
; What the Program Does:
; 1.Initialization: Clears screen and displays welcome message
; 2.Input Loop:
;     Shows prompt "[HEX]="
;     Reads user input (up to 64 characters)
;     Parses first and second hex numbers from input
;     Performs calculations and display results
; 3.Exit Conditions: Empty input or AR2 key exits to monitor
;
; Key Components:
; System Calls (ROM routines):
;   GETCHAR (0F803H): Read character with wait
;   PUTCHAR (0F809H): Output character
;   PUTLINE (0F818H): Output null-terminated string
;   RETURN (0F89DH): Return to system monitor
;
; String Utilities:
;   GETLINE: Read line with editing (backspace support)
;   CLS: Clear screen
;   NEWLINE: Output CR+LF
;   STRLEN: Get string length
;   LTRIM/RTRIM: Remove leading/trailing spaces
;   ITEM: Extract nth word from string
;
;*******************************************************************************
                ORG     1C00H           

GETCHAR         EQU     0F803H           ; WAIT AND GET CHAR TO A
PUTCHAR         EQU     0F809H           ; PUT CHAR IN C
PUTHEX          EQU     0F815H           ; PUT HEX IN A
PUTLINE         EQU     0F818H           ; PUT STRING IN HL
RETURN          EQU     0F89DH           ; QUIT TO MONITOR

CHARZERO        EQU     00H
CHARBS          EQU     08H
CHARLF          EQU     0AH
CHARCR          EQU     0DH        
CHARCLS         EQU     1FH
CHARSPC         EQU     20H
CHARAR2         EQU     1BH
CHARQUEST       EQU     3FH

MAIN:           CALL    CLS
                LXI     HL,HELLO
                CALL    PUTLINE
                CALL    NEWLINE
MAINLOOP:       LXI     HL,PROMPT
                CALL    PUTLINE
                LXI     HL,LINE
                CALL    GETLINE
                ;CALL    NEWLINE
                LXI     HL,LINE
                MVI     A,CHARAR2
                CMP     M
                JZ      EXIT
                MVI     A,CHARZERO
                CMP     M
                JZ      EXIT
                LXI     HL,LINE
                LXI     DE,BUFFER1
                MVI     C,1
                CALL    ITEM
                CPI     00H
                JNZ     CONTINUE
                MVI     C,CHARQUEST
                CALL    PUTCHAR
                CALL    NEWLINE
                JMP     MAINLOOP       
CONTINUE:       LXI     HL,LINE
                LXI     DE,BUFFER2
                MVI     C,2
                CALL    ITEM
                CPI     00H
                JNZ     CONVERT
                MVI     C,CHARQUEST
                CALL    PUTCHAR
                CALL    NEWLINE
                JMP     MAINLOOP       
CONVERT:        LXI     HL,BUFFER1
                CALL    LTRIM
                LXI     HL,BUFFER1
                CALL    RTRIM
                LXI     HL,BUFFER1
                CALL    HEX2BIN
                SHLD    VALUE1
                LXI     HL,BUFFER2
                CALL    LTRIM
                LXI     HL,BUFFER2
                CALL    RTRIM
                LXI     HL,BUFFER2
                CALL    HEX2BIN
EVALUATE:       SHLD    VALUE2          
                LHLD    VALUE2          ; ADD
                XCHG
                LHLD    VALUE1
                CALL    ADD16                
                SHLD    RESULT
                CALL    NEWLINE
                LXI     HL,BUFFER1
                CALL    PUTLINE
                LXI     HL,ADDSTR
                CALL    PUTLINE
                LXI     HL,BUFFER2
                CALL    PUTLINE
                LXI     HL,EQUSTR
                CALL    PUTLINE
                LDA     RESULT+1
                CALL    PUTHEX
                LDA     RESULT
                CALL    PUTHEX
                CALL    NEWLINE
                          
                LHLD    VALUE2          ; SUBSTRACT
                XCHG
                LHLD    VALUE1
                CALL    SUB16
                SHLD    RESULT
                LXI     HL,BUFFER1
                CALL    PUTLINE
                LXI     HL,SUBSTR
                CALL    PUTLINE
                LXI     HL,BUFFER2
                CALL    PUTLINE
                LXI     HL,EQUSTR
                CALL    PUTLINE
                LDA     RESULT+1
                CALL    PUTHEX
                LDA     RESULT
                CALL    PUTHEX
                CALL    NEWLINE
                
                LHLD    VALUE2          ; MULTIPLY
                XCHG
                LHLD    VALUE1
                CALL    MUL16
                SHLD    RESULT
                LXI     HL,BUFFER1
                CALL    PUTLINE
                LXI     HL,MPYSTR
                CALL    PUTLINE
                LXI     HL,BUFFER2
                CALL    PUTLINE
                LXI     HL,EQUSTR
                CALL    PUTLINE
                LDA     RESULT+1
                CALL    PUTHEX
                LDA     RESULT
                CALL    PUTHEX
                CALL    NEWLINE

                LHLD    VALUE2          ; DIVIDE
                PUSH    HL
                POP     BC
                LHLD    VALUE1
                CALL    DIV16
                JNC     DIV_BY_ZERO 
                SHLD    REMINDER
                XCHG
                SHLD    RESULT
                LXI     HL,BUFFER1
                CALL    PUTLINE
                LXI     HL,DIVSTR
                CALL    PUTLINE
                LXI     HL,BUFFER2
                CALL    PUTLINE
                LXI     HL,EQUSTR
                CALL    PUTLINE
                LDA     RESULT+1
                CALL    PUTHEX
                LDA     RESULT
                CALL    PUTHEX
                LXI     HL,REMSTR
                CALL    PUTLINE
                LDA     REMINDER+1
                CALL    PUTHEX
                LDA     REMINDER
                CALL    PUTHEX
                JMP     DONE
DIV_BY_ZERO:    LXI     HL,DIVBYZERO
                CALL    PUTLINE
DONE:           CALL    NEWLINE
                CALL    NEWLINE
                JMP     MAINLOOP
EXIT:           JMP     RETURN

ADD16:          
;*******************************************************************************
; ADD TWO 16-BIT NUMBERS
; INPUT:        HL = FIRST NUMBER
;               DE = SECOND NUMBER
; OUTPUT:       HL = HL + DE
;*******************************************************************************
                MOV     A,L             ; LOAD LOW BYTE OF FIRST NUMBER
                ADD     E               ; ADD LOW BYTE OF SECOND NUMBER
                MOV     L,A             ; STORE RESULT IN LOW BYTE OF HL
                MOV     A,H             ; LOAD HIGH BYTE OF FIRST NUMBER
                ADC     D               ; ADD HIGH BYTE OF SECOND NUMBER WITH CARRY
                MOV     H,A             ; STORE RESULT IN HIGH BYTE OF HL
                RET                     ; RETURN WITH RESULT IN HL

SUB16:          
;*******************************************************************************
; SUBTRACT TWO 16-BIT NUMBERS
; INPUT:        HL = FIRST NUMBER (MINUEND)
;               DE = SECOND NUMBER (SUBTRAHEND)
; OUTPUT:       HL = HL - DE
;*******************************************************************************
                MOV     A,L             ; LOAD LOW BYTE OF MINUEND
                SUB     E               ; SUBTRACT LOW BYTE OF SUBTRAHEND
                MOV     L,A             ; STORE RESULT IN LOW BYTE OF HL
                MOV     A,H             ; LOAD HIGH BYTE OF MINUEND
                SBB     D               ; SUBTRACT HIGH BYTE WITH BORROW
                MOV     H,A             ; STORE RESULT IN HIGH BYTE OF HL
                RET                     ; RETURN WITH RESULT IN HL

MUL16:
;*******************************************************************************
; MULTIPLY TWO 16-BIT NUMBERS
; INPUT:        HL = FIRST NUMBER 
;               DE = SECOND NUMBER 
; OUTPUT:       HL = HL * DE
;*******************************************************************************
                PUSH    HL
                POP     BC
                LXI     HL,0000H
                MVI     A,15
MUL16_LOOP:     PUSH    PSW
                ORA     D
                JP      MUL16_SHIFT
                DAD     BC    
MUL16_SHIFT:    DAD     HL
                XCHG
                DAD     HL
                XCHG
                POP     PSW
                DCR     A
                JNZ     MUL16_LOOP
                ORA     D
                RP
                DAD     BC
                RET

DIV16:  
;*******************************************************************************
; ПОДПРОГРАММА ДЕЛЕНИЯ ЦЕЛЫХ ДВОИЧНЫХ ЧИСЕЛ БЕЗ ЗНАКА ФОРМАТА 16:16
; МЕТОД ДЕЛЕНИЯ  С ВОССТАНОВЛЕНЕМ ОСТАТКА
; ВХОД HL ДЕЛИМОЕ, ВС - ДЕЛИТЕЛЬ
; ВЫХОД DE ЧАСТНОЕ, HL ОСТАТОК, CY=0 ДЕЛИТЕЛЬ НУЛЬ
;*******************************************************************************
                XRA     A
                ORA     A
                ORA     C
                RZ      ; ЕСЛИ ДЕЛИТЕЛЬ = 0
                XCHG
                LXI     HL,0
                MVI     A,16
LOOP:           PUSH    PSW
                DAD     HL
                XRA     A
                XCHG
                DAD     HL
                XCHG
                ADC     L
                SUB     C
                MOV     L,A
                MOV     A,H
                SBB     B
                MOV     H,A
                INX     DE
                JNC     PER
                DAD     BC
                DCX     DE
PER:            POP     PSW
                DCR     A
                JNZ     LOOP
                STC
                RET
                
GETLINE:           
;*******************************************************************************
; INPUT A STRING INTO THE INBUF BUFFER, UP TO 64 CHARACTERS
; USES THE GETCHAR (INPUT A CHARACTER, WAITING IN A)
; INPUT:        HL - THE BUFFER ADDRESS
; OUTPUT:       BUFFER FILLED WITH STRING, NULL TERMINATED, 
;               C - CHARACTERS READ != STRING LENGTH!
;*******************************************************************************
                PUSH    HL              ; SAVE BUFFER ADDRESS
                MVI     B,40H           ; B=MAX LENGTH COUNTER (64 CHARS)
                MVI     C,00H           ; C=CURRENT CHARACTER COUNT
GETLINE_LOOP:   CALL    GETCHAR         ; GET CHARACTER IN A
                CPI     CHARCR          ; CHECK FOR CARRIAGE RETURN
                JZ      GETLINE_DONE    ; IF CR, FINISH INPUT
                CPI     CHARBS          ; CHECK FOR BACKSPACE
                JZ      GETLINE_BS      ; HANDLE BACKSPACE
                MOV     D,A             ; SAVE CHARACTER
                MOV     A,C             ; CHECK CURRENT COUNT
                CMP     B               ; COMPARE WITH MAX LENGTH
                JNC     GETLINE_LOOP    ; IF AT MAX, IGNORE INPUT
                MOV     A,D             ; RESTORE CHARACTER
                MOV     M,A             ; STORE CHARACTER IN BUFFER
                INX     HL              ; MOVE TO NEXT BUFFER POSITION
                INR     C               ; INCREMENT CHARACTER COUNT
                MOV     E,A             ; PUT CHAR IN E FOR OUTPUT
                PUSH    BC              ; SAVE REGISTERS
                PUSH    DE
                MOV     C,E             ; PUT CHAR IN C FOR PUTCH
                CALL    PUTCHAR         ; ECHO THE CHARACTER
                POP     D               ; RESTORE REGISTERS
                POP     B
                JMP     GETLINE_LOOP    ; CONTINUE LOOP
GETLINE_BS:     MOV     A,C             ; CHECK IF WE HAVE CHARACTERS
                ORA     A               ; TEST IF COUNT IS ZERO
                JZ      GETLINE_LOOP    ; IF NO CHARS, IGNORE BACKSPACE
                DCX     HL              ; MOVE BACK IN BUFFER
                DCR     C               ; DECREMENT CHARACTER COUNT
                PUSH    BC              ; SAVE REGISTERS
                MVI     C,CHARBS        ; BACKSPACE CHARACTER
                CALL    PUTCHAR         ; OUTPUT BACKSPACE
                MVI     C,CHARSPC       ; SPACE CHARACTER
                CALL    PUTCHAR         ; OUTPUT SPACE
                MVI     C,CHARBS        ; BACKSPACE CHARACTER
                CALL    PUTCHAR         ; OUTPUT BACKSPACE
                POP     BC              ; RESTORE REGISTERS
                JMP     GETLINE_LOOP    ; CONTINUE LOOP
GETLINE_DONE:   MVI     M,CHARZERO      ; NULL TERMINATE THE STRING
                POP     HL              ; RESTORE ORIGINAL BUFFER ADDRESS
                RET

CLS:            
;*******************************************************************************
; CLEAR THE SCREEN
; USES THE PUTCHAR SYSTEM CALL TO OUTPUT THE CLEAR SCREEN CHARACTER
; INPUT:        NONE 
; OUTPUT:       NONE
;*******************************************************************************
                PUSH    BC              ; PRESERVE CALLER'S STATE
                MVI     C,CHARCLS       ; LOAD CLEAR SCREEN CHARACTER (1FH)
                CALL    PUTCHAR         ; CALL SYSTEM ROUTINE TO OUTPUT CHARACTER
                POP     BC              ; RESTORE BC REGISTER PAIR TO ORIGINAL STATE
                RET                     

NEWLINE:
;*******************************************************************************
; OUTPUT A CARRIAGE RETURN AND LINE FEED SEQUENCE
; USES PUTCHAR (INPUT A CHARACTER, WAITING IN A)
; INPUT:        NONE
; OUTPUT:       NONE
;*******************************************************************************
                PUSH    BC              ; PRESERVE CALLER'S STATE
                MVI     C,CHARLF        ; LOAD LINE FEED CHARACTER (0AH)
                CALL    PUTCHAR         ; CALL MONITOR ROUTINE TO OUTPUT
                MVI     C,CHARCR        ; LOAD CARRIAGE RETURN CHARACTER (0DH)
                CALL    PUTCHAR         ; CALL MONITOR ROUTINE TO OUTPUT
                POP     BC              ; RESTORE BC REGISTER PAIR
                RET
                
STRLEN:
;*******************************************************************************
; GET LENGTH OF NULL TERMINATED STRING
; INPUT:        HL - POINTER TO NULL TERMINATED STRING
; OUTPUT:       C  - LENGTH OF STRING
;               A  - LAST CHARACTER (0 FOR NULL TERMINATED)
;*******************************************************************************
                PUSH    HL              ; SAVE STRING POINTER
                MVI     C,00H           ; INITIALIZE LENGTH COUNTER
STRLEN_LOOP:    MOV     A,M             ; GET CHARACTER
                ORA     A               ; CHECK FOR NULL TERMINATOR
                JZ      STRLEN_DONE     ; IF NULL, WE'RE DONE
                INR     C               ; INCREMENT COUNTER
                INX     HL              ; MOVE TO NEXT CHARACTER
                JMP     STRLEN_LOOP     ; CONTINUE LOOP
STRLEN_DONE:    POP     HL              ; RESTORE ORIGINAL POINTER
                RET

LTRIM:
;*******************************************************************************
; REMOVE LEADING SPACES FROM NULL TERMINATED STRING
; INPUT:        HL - POINTER TO NULL TERMINATED STRING
; OUTPUT:       HL - POINTER TO TRIMMED STRING (MODIFIED IN PLACE)
;*******************************************************************************
                PUSH    DE              ; SAVE ORIGINAL DE
                PUSH    HL              ; DE=HL (COPY OF ORIGINAL POINTER)
                POP     DE              
LTRIM_SKIP:     MOV     A,M             ; LOAD CURRENT CHARACTER
                ORA     A               ; CHECK FOR NULL TERMINATOR
                JZ      LTRIM_MOVE      ; IF END OF STRING, MOVE WHAT WE HAVE
                CPI     CHARSPC         ; CHECK FOR SPACE                 
                JNZ     LTRIM_MOVE      ; IF NOT SPACE, START MOVING FROM HERE
                INX     HL              ; MOVE TO NEXT CHARACTER
                JMP     LTRIM_SKIP      ; CONTINUE SKIPPING SPACES
LTRIM_MOVE:     ; AT THIS POINT, HL POINTS TO FIRST NON-SPACE CHARACTER
                ; DE POINTS TO START OF BUFFER
                PUSH    HL              ; BC=SOURCE POINTER
                POP     BC              
                PUSH    DE              ; HL=DESTINATION POINTER (START OF BUFFER)
                POP     HL
LTRIM_COPY:     LDAX    BC              ; LOAD BYTE FROM SOURCE (BC)
                MOV     M,A             ; STORE BYTE TO DESTINATION (HL)
                ORA     A               ; CHECK FOR NULL TERMINATOR
                JZ      LTRIM_DONE      ; IF NULL, WE'RE DONE
                INX     BC              ; MOVE SOURCE POINTER
                INX     HL              ; MOVE DESTINATION POINTER
                JMP     LTRIM_COPY      ; CONTINUE COPYING
LTRIM_DONE:     POP     DE              ; RESTORE ORIGINAL DE  
                RET

RTRIM: 
;*******************************************************************************
; REMOVE TRAILING SPACES FROM NULL TERMINATED STRING
; INPUT:        HL - POINTER TO NULL TERMINATED STRING
; OUTPUT:       STRING MODIFIED IN PLACE WITH TRAILING SPACES REMOVED
;*******************************************************************************
                PUSH    HL              ; SAVE ORIGINAL POINTER
                PUSH    DE              ; SAVE DE
                CALL    STRLEN          ; GET STRING LENGTH IN C
                MOV     A,C             ; CHECK IF STRING IS EMPTY
                ORA     A
                JZ      RTRIM_EXIT      ; IF EMPTY, NOTHING TO TRIM
                MOV     E,C             ; SAVE LENGTH
                MVI     D,00H           ; DE=LENGTH
                DCX     DE              ; DE=LENGTH-1 (POINT TO LAST CHAR)
                DAD     D               ; HL POINTS TO LAST CHARACTER
RTRIM_LOOP:     MOV     A,M             ; GET CURRENT CHARACTER
                CPI     CHARSPC         ; CHECK IF SPACE
                JNZ     RTRIM_FOUND     ; IF NOT SPACE, WE FOUND END
                DCX     HL              ; MOVE BACK ONE CHARACTER
                MOV     A,E             ; CHECK POSITION
                CPI     01H             ; IF WE'RE AT START OF STRING
                JZ      RTRIM_EMPTY     ; MAKE STRING EMPTY
                DCR     E               ; DECREMENT POSITION COUNTER
                JMP     RTRIM_LOOP
RTRIM_FOUND:    INX     HL              ; POINT AFTER LAST NON-SPACE CHAR
                JMP     RTRIM_SET_NULL
RTRIM_EMPTY:    POP     DE              ; RESTORE REGISTERS
                POP     HL              ; RESTORE ORIGINAL POINTER
                MVI     M,CHARZERO      ; MAKE EMPTY STRING
                RET
RTRIM_SET_NULL: MVI     M,CHARZERO      ; NULL TERMINATE THE STRING
RTRIM_EXIT:     POP     DE              ; RESTORE REGISTERS
                POP     HL              ; RESTORE ORIGINAL POINTER
                RET

ITEM:   
;*******************************************************************************
; COPIES WORD FROM TRIMMED NULL TERMINATED STRING
; INPUT:        HL - POINTER TO NULL TERMINATED STRING
;               DE - POINTER TO BUFFER FOR COPIED WORD
;               C - NUMBER (1, 2, 3..) OF WORD TO COPY 
; OUTPUT:       A -  A=0 IF WORD DOES NOT COPIED/EXIST, A=1 IF FOUND
;*******************************************************************************
                PUSH    HL              ; SAVE ORIGINAL POINTER
                XRA     A               ; CLEAR ACCUMULATOR
                MOV     B,A             ; B=CURRENT_WORD=0 (WORD COUNTER)
ITEM_FIND:      MOV     A,M             ; LOAD CURRENT CHARACTER FROM SOURCE               
                INX     HL              ; ADVANCE SOURCE POINTER
                ORA     A               ; CHECK FOR NULL TERMINATOR
                JZ      ITEM_NF         ; IF END OF STRING, WORD NOT FOUND
                CPI     CHARSPC         ; CHECK IF CURRENT CHAR IS SPACE
                JZ      ITEM_FIND       ; SKIP SPACES
                INR     B               ; FOUND START OF WORD, INCREMENT COUNTER
                MOV     A,B             ; LOAD CURRENT WORD NUMBER
                CMP     C               ; COMPARE WITH REQUESTED WORD NUMBER
                JNZ     ITEM_SKIP       ; IF NOT THE REQUESTED WORD, SKIP IT
ITEM_COPY:      DCX     HL              ; STEP BACK TO THE FIRST CHARACTER OF WORD
ITEM_CPYLP:     MOV     A,M             ; LOAD CHARACTER FROM SOURCE
                INX     HL              ; ADVANCE SOURCE POINTER
                XCHG                    ; SWAP HL AND DE (HL NOW POINTS TO DEST)
                MOV     M,A             ; STORE CHARACTER TO DESTINATION
                INX     HL              ; ADVANCE DESTINATION POINTER
                XCHG                    ; SWAP BACK (HL=SOURCE, DE=DEST)
                ORA     A               ; CHECK IF CHARACTER IS NULL
                JZ      ITEM_COPIED     ; IF NULL, WE'RE DONE COPYING
                CPI     CHARSPC         ; CHECK IF CHARACTER IS SPACE
                JNZ     ITEM_CPYLP      ; IF NOT SPACE, CONTINUE COPYING
ITEM_COPIED:    MVI     A,CHARZERO      ; LOAD NULL TERMINATOR
                XCHG                    ; SWAP TO DESTINATION POINTER
                MOV     M,A             ; STORE NULL TERMINATOR
                INX     HL              ; ADVANCE DESTINATION POINTER
                XCHG                    ; SWAP BACK TO SOURCE POINTER
                MVI     A,01H           ; SET SUCCESS FLAG
                POP     HL              ; RESTORE ORIGINAL POINTER
                RET                     ; RETURN WITH A=1 (SUCCESS)
ITEM_SKIP:      NOP                     ; SKIP TO THE NEXT WORD
ITEM_TO_SPC:    ORA     A               ; CHECK IF END OF STRING
                JZ      ITEM_NF         ; IF END, WORD NOT FOUND
                CPI     CHARSPC         ; CHECK IF CURRENT CHAR IS SPACE
                JZ      ITEM_FIND       ; IF SPACE, LOOK FOR NEXT WORD
                MOV     A,M             ; LOAD NEXT CHARACTER
                INX     HL              ; ADVANCE POINTER
                JMP     ITEM_TO_SPC     ; CONTINUE SEARCHING FOR SPACE
ITEM_NF:        NOP                     ; ITEM NOT FOUND
                XCHG                    ; SWAP TO DESTINATION POINTER
                MOV     M,A             ; STORE NULL TERMINATOR (A=0)
                INX     HL              ; ADVANCE DESTINATION POINTER
                XCHG                    ; SWAP BACK TO SOURCE POINTER
                XRA     A               ; CLEAR ACCUMULATOR (A=0=FAILURE)
                POP     HL              ; RESTORE ORIGINAL HL
                RET                     ; RETURN WITH A=0 (FAILURE)

HEX2BIN:
;*******************************************************************************
; CONVERT ASCII HEX STRING TO BINARY
; INPUT:        HL - POINTER TO NULL TERMINATED STRING
; OUTPUT:       HL - BINARY VALUE (0-65535)
;*******************************************************************************
                PUSH    DE
                LXI     DE,0000H        ; RESULT
                MOV     A,M             ; GET FIRST CHARACTER FROM STRING
                CALL    A2HEX           ; CONVERT ASCII HEX TO BINARY (0-15)
                RLC                     ; ROTATE LEFT TO SHIFT BITS 4 POSITIONS
                RLC
                RLC
                RLC
                MOV     D,A             ; STORE HIGH NIBBLE IN D REGISTER
                INX     HL              ; MOVE TO NEXT CHARACTER IN STRING
                MOV     A,M             ; GET SECOND CHARACTER FROM STRING
                CALL    A2HEX           ; CONVERT ASCII HEX TO BINARY (0-15)
                ORA     D               ; COMBINE WITH FIRST NIBBLE TO FORM FIRST BYTE
                MOV     D,A             ; STORE FIRST BYTE IN D REGISTER
                INX     HL              ; MOVE TO NEXT CHARACTER IN STRING
                MOV     A,M             ; GET THIRD CHARACTER FROM STRING
                CALL    A2HEX           ; CONVERT ASCII HEX TO BINARY (0-15)
                RLC                     ; ROTATE LEFT TO SHIFT BITS 4 POSITIONS
                RLC
                RLC
                RLC
                MOV     E,A             ; STORE HIGH NIBBLE IN E REGISTER
                INX     HL              ; MOVE TO NEXT CHARACTER IN STRING
                MOV     A,M             ; GET FOURTH CHARACTER FROM STRING
                CALL    A2HEX           ; CONVERT ASCII HEX TO BINARY (0-15)
                ORA     E               ; COMBINE WITH THIRD NIBBLE TO FORM SECOND BYTE
                MOV     E,A             ; STORE SECOND BYTE IN E REGISTER
                XCHG                    ; PUT RESULT IN HL
                POP     DE
                RET                     ; RETURN WITH BINARY VALUE IN HL
                
A2HEX:          
;*******************************************************************************
; CONVERT SINGLE ASCII HEX CHARACTER TO BINARY VALUE
; INPUT:        A - ASCII CHARACTER ('0'-'9', 'A'-'F')
; OUTPUT:       A - HEX VALUE (0-15)
;*******************************************************************************
                SUI     '0'     ; SUBTRACT ASCII '0' TO GET 0-9
                CPI     10      ; CHECK IF CHARACTER IS DIGIT 0-9
                JC      A2HEX_SKIP ; JUMP IF DIGIT VALUE < 10
                SUI     7       ; FIX VALUE IF A-F
A2HEX_SKIP:     RET

HELLO           DB      17H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H
                DB      03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H
                DB      03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H,03H
                DB      03H,03H,03H,03H,03H,03H,03H,03H,03H,17H,CHARCR,CHARLF
                DB      17H,'                  HEX CALCULATOR                  '
                DB      17H,CHARCR,CHARLF
                DB      17H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H
                DB      14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H
                DB      14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H,14H
                DB      14H,14H,14H,14H,14H,14H,14H,14H,14H,17H,CHARCR,CHARLF
                DB      CHARCR,CHARLF
                DB      'ENTER TWO HEXADECIMAL NUMBERS SEPARATED BY A SPACE.'
                DB      CHARCR,CHARLF
                DB      'THE PROGRAM WILL DISPLAY THEIR SUM, DIFFERENCE,'
                DB      CHARCR,CHARLF
                DB      'PRODUCT AND QUOTIENT. '
                DB      'TO EXIT PRESS [AR2] OR [ENTER].',CHARCR,CHARLF,CHARZERO
PROMPT          DB      '[HEX]=',CHARZERO
LINE            DS      65          
BUFFER1         DS      65
BUFFER2         DS      65
ADDSTR          DB      '+',CHARZERO
SUBSTR          DB      '-',CHARZERO
DIVSTR          DB      '/',CHARZERO
MPYSTR          DB      '*',CHARZERO
EQUSTR          DB      '=',CHARZERO
REMSTR          DB      ', REM=',CHARZERO
DIVBYZERO       DB      'DIVISION BY ZERO',CHARZERO
VALUE1          DW      0
VALUE2          DW      0
RESULT          DW      0
REMINDER        DW      0
                END 
                