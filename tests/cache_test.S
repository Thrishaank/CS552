# Cache Test Program
# Tests various cache scenarios:
# 1. Sequential accesses (should have good spatial locality)
# 2. Repeated accesses (should have good temporal locality)
# 3. Strided accesses (tests set-associativity)
# 4. Write-through behavior
# 5. Cache line fills

.text
.globl _start

_start:
    # Test 1: Sequential instruction fetches (good spatial locality)
    # These instructions are in the same cache line
    addi x1, x0, 1          # x1 = 1
    addi x2, x0, 2          # x2 = 2
    addi x3, x0, 3          # x3 = 3
    addi x4, x0, 4          # x4 = 4
    
    # Test 2: Sequential loads (spatial locality in data cache)
    lui x10, 0x00000        # Base address for loads
    lw x5, 0(x10)           # Load from address 0 (miss, then fill cache line)
    lw x6, 4(x10)           # Load from address 4 (hit, same cache line)
    lw x7, 8(x10)           # Load from address 8 (hit, same cache line)
    lw x8, 12(x10)          # Load from address 12 (hit, same cache line)
    
    # Test 3: Store operations (write-through test)
    lui x11, 0x00100        # Base address 0x100 for stores
    addi x12, x0, 0xAA      # Pattern to write
    sw x12, 0(x11)          # Store to 0x100 (miss, allocate, write-through)
    sw x12, 4(x11)          # Store to 0x104 (hit, write-through)
    
    # Test 4: Load what we just stored (temporal locality)
    lw x13, 0(x11)          # Should be cache hit
    lw x14, 4(x11)          # Should be cache hit
    
    # Test 5: Strided access pattern (tests set conflicts)
    # Access addresses that map to same set but different cache lines
    # Set index uses bits [8:4], so stride by 512 (0x200) to hit same set
    lui x15, 0x00200        # Address 0x200
    lw x16, 0(x15)          # Load from 0x200 (different set from 0x100)
    
    lui x15, 0x00400        # Address 0x400  
    lw x17, 0(x15)          # Load from 0x400 (different set again)
    
    # Test 6: Repeated access to same location (temporal locality)
    lui x18, 0x00000
    lw x19, 0(x18)          # First access (should be hit if still in cache)
    lw x20, 0(x18)          # Second access (definitely hit)
    lw x21, 0(x18)          # Third access (definitely hit)
    
    # Test 7: Store multiple values and read back
    lui x22, 0x00300        # Base address 0x300
    addi x23, x0, 0x11
    addi x24, x0, 0x22
    addi x25, x0, 0x33
    addi x26, x0, 0x44
    
    sw x23, 0(x22)          # Store 0x11 to 0x300
    sw x24, 4(x22)          # Store 0x22 to 0x304
    sw x25, 8(x22)          # Store 0x33 to 0x308
    sw x26, 12(x22)         # Store 0x44 to 0x30C
    
    # Read back to verify
    lw x27, 0(x22)          # Should get 0x11
    lw x28, 4(x22)          # Should get 0x22
    lw x29, 8(x22)          # Should get 0x33
    lw x30, 12(x22)         # Should get 0x44
    
    # Test 8: Jump to test instruction cache behavior
    jal x31, test_jump
    addi x1, x1, 1          # Shouldn't execute (we won't return)
    
test_jump:
    # This creates a non-sequential instruction fetch
    addi x2, x2, 10         # x2 = 12
    addi x3, x3, 20         # x3 = 23
    
    # Final instruction - end test
    # In real system would halt, but we'll just trap on illegal instruction
    .word 0x00000000        # Illegal instruction to end test
