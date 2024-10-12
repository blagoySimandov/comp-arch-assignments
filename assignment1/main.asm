.data 
  name_and_number: .asciiz "Blagoy Simandov 123776895"
  init_prompt_part_2: .asciiz " is implementing the core assignment\n"
  user_prompt_for_number: .asciiz "Enter any real number:"
  input_str: .space 100
  invalid_input_msg: .asciiz "Invalid_input. Only digits and '.' characters are allowed"
  zero_float: .float 0.0
  dot_one_float: .float 0.1
  ten_float: .float 10.0

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
  mov.s $f12 $f3  
  jal printfloat
  
  j osexit

printstr:
  li $v0, 4
  syscall
  jr $ra
printfloat:
  li $v0, 2
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
  sw $s2, 8($sp)         # Store $s2  Using it to keep track of the exponent
  sw $s1, 4($sp)         # Store $s1 Using it to store the fraction
  sw $s0, 0($sp)         # Store $s0   Using it to store the string

  li $s3, 0 # using s0 for loop counter
  li $s4, 0 # Flag/ counter for elements after the dot.
  l.s $f0, zero_float # Initialize fraction to 0.0
  l.s $f1, ten_float # Initialize multiplier to 10.0
  l.s $f2, dot_one_float # Initialize divisor to 0.1

  # Store $a0 into $s0
  move $s0, $a0
  loop:
    lb $a0, 0($s0) # loads the first byte of the string
    lb $s5, 0($s0) # loads the first byte of the string into a saved register as we are gonna need it post validate
    beq $a0, $zero, end # if null exit loop
    li $t7, 0x0A
    beq $a0, $t7, end # if carriage return exit loop
    jal validate_char # in v0 we should have 1 if it is a digit and 0 if it is a dot.
    addi $s0, $s0, 1 # increment the string pointer
    addi $s3, $s3, 1 # increment loop counter

    beq $v0, $zero, else
    ifnumber:
      bne $s4, $zero, if_after_dot
      # If not after dot
      subi $t0, $s5, 0x30       # Convert ASCII to integer
      mtc1 $t0, $f3             # Move integer to floating-point register
      cvt.s.w $f3, $f3          # Convert integer to float
      mul.s $f0, $f0, $f1       # Multiply current fraction by 10
      add.s $f0, $f0, $f3       # Add the new digit to the fraction
      j endif_after_dot

    if_after_dot:
      addi $s4, $s4, 1          # Increment counter for elements after the dot
      subi $t0, $s5, 0x30       # Convert ASCII to integer
      mtc1 $t0, $f3             # Move integer to floating-point register
      cvt.s.w $f3, $f3          # Convert integer to float
      mul.s $f3, $f3, $f2       # Multiply digit by 0.1, 0.01, etc.
      add.s $f0, $f0, $f3       # Add the new digit to the fraction
      mul.s $f2, $f2, $f2       # Update divisor for next digit

    endif_after_dot:
      j endif
    else:
      bne $s4, $zero, invalid_input # if s4 is not zero then there are more than one dot ? should go into invalid_input
      li $s4, 1
    endif:
      j loop
  end:
    # Pop to restore all the values from the stack that were lost in the procedure
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $s5, 20($sp)
    lw $ra, 24($sp)
    addi $sp, $sp, 28

    jr $ra

# Returns 1 in v0 if the char was a digit and 0 if it was a dot, Exits if invalid_input
validate_char:
  li $t7, 48             # ASCII '0'
  li $t8, 57             # ASCII '9'
  li $t9, 46             # ASCII '.'
  blt $a0, $t7, check_dot  # Check if character is below '0'
  bgt $a0, $t8, invalid_input  # Check if character is above '9'
  li $v0, 1
  j valid_input          # Jump to valid input if it's a digit
  check_dot:
    li $v0, 0 # Set output to dot
    beq $a0, $t9, valid_input  # Check if character is '.'
    j invalid_input        # Jump to invalid input if it's not a digit or '.'
  valid_input:
    jr $ra
  invalid_input:
    la $a0, invalid_input_msg
    jal printstr
    jal osexit
