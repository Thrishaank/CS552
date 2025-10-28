    .option norvc               
    .text
    .globl _start
_start:
    li   a0, 5          # N = 5  
    li   a1, 1          # res = 1

1:  beqz a0, 2f         # while (N != 0)
    mv   a2, a1         # a = res
    mv   a3, a0         # b = N
    jal  ra, mul        # a4 = a*b
    mv   a1, a4         # res = a*b
    addi a0, a0, -1     # N--
    j    1b

2:  j    2b             # sit forever with res in a1

mul:
    li   a4, 0           # accumulator  = 0

3:  beqz a3, 4f          # If B == 0, jump to 4 

    andi t0, a3, 1       # Check if LSB of B == 1
    beqz t0, 5f          # If LSB == 0, skip addition 

    add  a4, a4, a2      # If LSB == 1, add (a2) to (a4)

5:  slli a2, a2, 1       # Shift A left by 1
    srli a3, a3, 1       # Shift B right by 1 
    j    3b              # Jump back to 3 to check next bit of B

4:  ret                  # Ret when B=0, and product is in a4