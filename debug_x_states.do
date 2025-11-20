# Debug script to identify X states
quit -sim
file delete -force work
vlib work

# Compile files
vlog rtl/d_ff.v rtl/rf.v rtl/imm.v rtl/alu.v
vlog rtl/if_id_reg.v rtl/id_ex_reg.v rtl/ex_mem_reg.v rtl/mem_wb_reg.v
vlog rtl/fetch.v rtl/decode.v rtl/execute.v rtl/memory.v rtl/writeback.v
vlog rtl/hart.v tb/tb.v

# Start simulation
vsim hart_tb

# Add critical signals to identify X states
add wave sim:/hart_tb/clk
add wave sim:/hart_tb/rst
add wave -hex sim:/hart_tb/dut/pc_if
add wave -hex sim:/hart_tb/dut/valid_if
add wave -hex sim:/hart_tb/dut/valid_id
add wave -hex sim:/hart_tb/dut/valid_ex
add wave -hex sim:/hart_tb/dut/valid_mem
add wave -hex sim:/hart_tb/dut/valid_wb

# Check pipeline register connections
add wave -hex sim:/hart_tb/dut/instruction_id
add wave -hex sim:/hart_tb/dut/instruction_ex
add wave -hex sim:/hart_tb/dut/instruction_mem
add wave -hex sim:/hart_tb/dut/instruction_wb

# Check key control signals
add wave -hex sim:/hart_tb/dut/branch_taken
add wave -hex sim:/hart_tb/dut/decode_trap_id
add wave -hex sim:/hart_tb/dut/decode_trap_ex

# Run for a short time to see initial behavior
run 100ns

# Check for X states
echo "Checking for unknown states..."
echo "If you see 'xxxx' or red values, these indicate uninitialized signals."

# Add memory interface signals
add wave -hex sim:/hart_tb/imem_raddr
add wave -hex sim:/hart_tb/imem_rdata

run 100ns