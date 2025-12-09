    .option norvc               
    .text
    .globl _start

# Compute factorial of 5 and store result in register a1 (x11)
# Result: 5! = 120 = 0x78

_start:
    li   a0, 5          # N = 5 (input number)
    li   a1, 1          # result = 1 (accumulator)

factorial_loop:
    beqz a0, done       # if N == 0, we're done
    
    # Multiply a1 by a0 using shift-and-add
    mv   a2, a1         # a2 = current result (multiplicand)
    mv   a3, a0         # a3 = N (multiplier)
    li   a4, 0          # a4 = product accumulator
    
multiply:
    beqz a3, mult_done  # if multiplier == 0, done
    andi t0, a3, 1      # check LSB of multiplier
    beqz t0, mult_skip  # if LSB is 0, skip addition
    add  a4, a4, a2     # product += multiplicand

mult_skip:
    slli a2, a2, 1      # multiplicand <<= 1
    srli a3, a3, 1      # multiplier >>= 1
    j    multiply

mult_done:
    mv   a1, a4         # result = product
    addi a0, a0, -1     # N = N - 1
    j    factorial_loop # repeat

done:
    # Result is now in a1 (x11)
    # Expected: 5! = 120 = 0x78
    # For hardware testing, keep looping to maintain LED display
    j    done

