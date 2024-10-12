.data
  name_and_number: .asciiz "Blagoy Simandov 123776895"
  init_prompt_part_2: .asciiz " is implementing the bonus assignment\n"
  user_prompt_for_number: .asciiz "Enter any real number (not only xxx.yyy) including negative:"
  input_str: .space 100
  multiple_minus_error_msg: .asciiz "Error: More than one minus sign is not allowed."
  multiple_dot_error_msg: .asciiz "Error: More than one decimal point is not allowed."
  invalid_input_msg: .asciiz "Error: Invalid character encountered. Only digits, '.', and '-' are allowed."
  zero_float: .float 0.0
  dot_one_float: .float 0.1
  minus_one_float: .float -1.0
  ten_float: .float 10.0
  sign_msg: .asciiz "The sign of your number is: \n"
  exponent_msg: .asciiz "The exponent of your number is: \n"   # Message for exponent with newline
  fraction_msg: .asciiz "The fraction of your number is: \n"
  hex_digits:   .asciiz "0123456789abcdef"                  # hexadecimal characters
  hex_result:      .space 11   #  0x + 8 hex digits + null terminator
  newline:      .asciiz "\n"                                # Newline string
.text
.globl main
main:
  print_name_and_number:
    la $a0, name_and_number
    jal printstr
  
  print_rest:
    la $a0, init_prompt_part_2
    jal printstr

  print_prompt:
    la $a0, user_prompt_for_number
    jal printstr

  store_input:
    la $a0, input_str
    li $a1, 100
    jal readstr
    jal str2float
  mov.s $f12 $f0
  mfc1 $a0, $f0

  jal print_float_parts  # Jump and link to print_float_parts procedure
  j osexit

print_newline:
  subi $sp, $sp, 4
  sw $a0, ($sp)

  la $a0, newline
  li $v0, 4
  syscall
  
  lw $a0, ($sp)#restore argument
  addi $sp, $sp, 4

  jr $ra
printstr:
  li $v0, 4
  syscall
  jr $ra

printint:
  li $v0, 1
  syscall
  jr $ra
readstr:
  li $v0, 8
  syscall
  jr $ra

osexit:
  li $v0, 10
  syscall

# a0- address of string to convert
# will store the fraction in $f0
str2float:
  # Push $s0 to the stack
  subi $sp, $sp, 28     # Decrement stack pointer

  sw $ra, 24($sp)         # Store the return register
  sw $s5, 20($sp)         # Storing s5 as we are going to use to hold the current char
  sw $s4, 16($sp)         # Store $s4 Using it as a flag to indicate if we have encountered a dot. Also as a counter for the elements after the dot.
  sw $s3, 12($sp)         # Store $s3  Using as a loop counter
  sw $s2, 8($sp)  #Using it as zero flag
  sw $s1, 4($sp)         #  using it as a flag if minus char was encountered
  sw $s0, 0($sp)         # Store $s0   Using it to store the string

  li $s2, 0 # using s2 as minus flag
  li $s3, 0 # using s0 for loop counter
  li $s4, 0 # Flag/ counter for elements after the dot.
  l.s $f0, zero_float # Initialize fraction to 0.0
  l.s $f1, ten_float # Initialize multiplier to 10.0
  l.s $f2, dot_one_float # Initialize divisor to 0.1
  l.s $f4, minus_one_float #Used to flip multiply the fraction at the end to

  # Store $a0 into $s0
  move $s0, $a0
  loop:
    lb $a0, 0($s0) # loads the first byte of the string
    lb $s5, 0($s0) # loads the first byte of the string into a saved register as we are gonna need it post validate
    beq $a0, $zero, end # if null exit loop
    li $t7, 0x0A
    beq $a0, $t7, end # if carriage return exit loop
    jal validate_char
    
    addi $s0, $s0, 1 # increment the string pointer
    addi $s3, $s3, 1 # increment loop counter
    beq $v0, $zero, ifnumber
    j else
    ifnumber:
      bne $s4, $zero, if_after_dot
      # If not after dot
      subi $t0, $s5, 0x30 # convert ascii to integer
      mtc1 $t0, $f3
      cvt.s.w $f3, $f3 #convert integer to float
      mul.s $f0, $f0, $f1 # multiply current fraction by 10 since it is not after the dot
      add.s $f0, $f0, $f3 # add the new digit to the fraction
      j endif_after_dot

      if_after_dot:
        addi $s4, $s4, 1          # increment counter for elements after the dot
        subi $t0, $s5, 0x30       # convert ascii to integer
        mtc1 $t0, $f3             # move integer to floating-point register
        cvt.s.w $f3, $f3          # convert integer to float
        mul.s $f3, $f3, $f2       # multiply digit by 0.1, 0.01, etc.
        add.s $f0, $f0, $f3       # add the new digit to the fraction
        div.s $f2, $f2, $f1 #Divide by ten 

      endif_after_dot:
    j endif
     else:
        li $t9, 2
        beq $v0, $t9, if_minus
        j else_minus
        
      if_minus: 
        bne $s2, $zero, multiple_minus_error # If s2 is not zero, show error for multiple minus signs
        li $s2, 1  # Set minus flag
        j endif_minus

      else_minus:
        bne $s4, $zero, multiple_dot_error  # If s4 is not zero, show error for multiple dots
        li $s4, 1  # Set dot flag
      endif_minus:
    endif:
      j loop
  end:
    # Pop to restore all the values from the stack that were lost in the procedure

    beq $s2, $zero, skip_inverse  # Skip multiplication if $s2 is 0
    mul.s $f0, $f0, $f4                  # Multiply $f0 by $f4 (fraction by -1)
    skip_inverse:

    lw $s0, 0($sp)
    lw $s2, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28


    jr $ra

# Returns 1 in v0 if the char was a digit, 0 if it was a dot and 2 if it was a minus sign, Exits if invalid_input
validate_char:
  li $t7, 48             # ASCII '0'
  li $t8, 57             # ASCII '9'
  li $t9, 46             # ASCII '.'
  li $t6, 45             # ASCII '-'
  blt $a0, $t7, check_dot_or_minus  # Check if character is below '0'
  bgt $a0, $t8, invalid_input  # Check if character is above '9'
  li $v0, 0
  j valid_input          # Jump to valid input if it's a digit
  check_dot_or_minus:
    beq $a0, $t9, set_dot  # Check if character is '.'
    beq $a0, $t6, set_minus  # Check if character is '-'
    j invalid_input        # Jump to invalid input if it's not a digit or '.'
  set_minus:
    li $v0, 2 # Set minus flag
    j valid_input # since minus is valid
  set_dot:
    li $v0, 1 # Set output to dot
    j valid_input # since dot is valid
  valid_input:
    jr $ra

#Fatalf
invalid_input:
  la $a0, invalid_input_msg
  li $a3, 2        # print to stderr
  jal printstr
  j osexit

multiple_minus_error:
  la $a0, multiple_minus_error_msg
  li $a3, 2        # print to stderr
  jal printstr
  j osexit

multiple_dot_error:
  la $a0, multiple_dot_error_msg
  li $a3, 2        # print to stderr
  jal printstr
  j osexit

#expects float at f0 as argument
print_float_parts:
    addi    $sp, $sp, -8       # allocate space on stack
    sw      $ra, 4($sp)        # save return address
    sw      $t0, 0($sp)        # save t0

    mfc1    $t0, $f0           # move f0 to t0
    # Extract exponent (bits 23-30)
    srl     $t1, $t0, 23       # shift right by 23 bits
    andi    $t1, $t1, 0xFF     # mask and get bit exponent
    andi    $t2, $t0, 0x7FFFFF # 0x7FFFFF  = 23 1s used for masking

    srl     $t3, $t0, 31       # shift right by 31 bits to get sign
    andi    $t3, $t3, 0x1

    la      $a0, sign_msg
    jal     printstr

    move    $a0, $t3
    jal     printint
    jal     print_newline

    la      $a0, exponent_msg
    jal     printstr

    # print exponent in hexadecimal
    move    $a0, $t1
    jal     print_hex
    jal     print_newline

    # print "the fraction of your number is: " followed by the fraction in hex
    la      $a0, fraction_msg
    jal     printstr

    # print fraction in hexadecimal
    move    $a0, $t2
    jal     print_hex

    lw      $t0, 0($sp)        # restore t0
    lw      $ra, 4($sp)        # restore return address
    addi    $sp, $sp, 8        # deallocate stack space
    jr      $ra                # return

#contract: a0-> pointer hex string.
print_hex:
  la $t2 hex_result #pointer to memory location where to store the hex output
 #start with 0x 
  li $t3, '0'
  sb $t3, 0($t2)
  li $t3, 'x'
  sb $t3, 1($t2)

  addi $t2 $t2 10 #start from the end coz big endian
  la $t4 hex_digits #pointer to sorted hex digits
  li $t3 0x00 #load null
  sb $t3 ($t2) # put null at the end
  subi $t2 $t2 1 #decrement pointer
  move $t0 $a0
  li $t5 0
  print_hex_loop:
    andi $t1 $t0 0xF #t1 now howds a hex digit 0-15
    add $t4 $t4 $t1
    
    lb $t3, 0($t4) #t3 will hold the ascii byte for the hex digit, Offseting by zero since the above instructions adds the offset
    sub $t4 $t4 $t1 # Return pointer to beggining of the string
    sb $t3 ($t2)
    #decrement hex_result pointer
    subi $t2 $t2 1
    addi $t5 $t5 1 #increment counter
    srl $t0 $t0 4 #shift right to get the next hex digit
    bne $t5 8 print_hex_loop
  exit_print_hex_loop: #this label isnt used. its here for better readability
    subi $t2 $t2 1  # decrement hex pointer again so it catches the 0 at the start

    subi $sp, $sp, 4
    sw $ra, 0($sp)     # push $ra to the stack
    
    move $a0 $t2
    jal printstr       # call printstr

    lw $ra, 0($sp)     # pop $ra from the stack
    addi $sp, $sp, 4   # deallocate space from the stack
    jr $ra
