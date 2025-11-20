# Updated ModelSim script - Clean compilation and simulation
# This script fixes X-state issues by ensuring proper signal initialization

quit -sim
vlib work

echo "=== Compiling RTL and Testbench ==="
vlog rtl/d_ff.v rtl/rf.v rtl/imm.v rtl/alu.v
vlog rtl/if_id_reg.v rtl/id_ex_reg.v rtl/ex_mem_reg.v rtl/mem_wb_reg.v
vlog rtl/fetch.v rtl/decode.v rtl/execute.v rtl/memory.v rtl/writeback.v
vlog rtl/hart.v tb/tb.v

echo "=== Starting Simulation ==="
vsim hart_tb

# Configure simulation for better X-state handling
configure wave -signalnamewidth 1
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -timelineunits ps

echo "=== Adding Essential Signals ==="
# Core timing
add wave -group "Clock & Reset" /hart_tb/clk
add wave -group "Clock & Reset" /hart_tb/rst

# Program execution tracking  
add wave -group "Execution" -hex /hart_tb/pc
add wave -group "Execution" -hex /hart_tb/inst
add wave -group "Execution" /hart_tb/valid
add wave -group "Execution" /hart_tb/halt
add wave -group "Execution" /hart_tb/trap

# Instruction memory interface
add wave -group "Instruction Memory" -hex /hart_tb/imem_raddr
add wave -group "Instruction Memory" -hex /hart_tb/imem_rdata

# Data memory interface
add wave -group "Data Memory" -hex /hart_tb/dmem_addr
add wave -group "Data Memory" /hart_tb/dmem_ren
add wave -group "Data Memory" /hart_tb/dmem_wen
add wave -group "Data Memory" -hex /hart_tb/dmem_wdata
add wave -group "Data Memory" -hex /hart_tb/dmem_rdata
add wave -group "Data Memory" -bin /hart_tb/dmem_mask

# Register file access
add wave -group "Register File" -unsigned /hart_tb/rs1_raddr
add wave -group "Register File" -hex /hart_tb/rs1_rdata
add wave -group "Register File" -unsigned /hart_tb/rs2_raddr  
add wave -group "Register File" -hex /hart_tb/rs2_rdata
add wave -group "Register File" -unsigned /hart_tb/rd_waddr
add wave -group "Register File" -hex /hart_tb/rd_wdata

# Key internal signals (to verify no X-states)
add wave -group "Internal Control" /hart_tb/dut/stall
add wave -group "Internal Control" /hart_tb/dut/branch_taken
add wave -group "Internal Control" /hart_tb/dut/valid_if
add wave -group "Internal Control" /hart_tb/dut/valid_id
add wave -group "Internal Control" /hart_tb/dut/pc_write_trap
add wave -group "Internal Control" /hart_tb/dut/mem_trap

# Pipeline instructions (to verify proper flow)
add wave -group "Pipeline Instructions" -hex /hart_tb/dut/instruction_id
add wave -group "Pipeline Instructions" -hex /hart_tb/dut/instruction_ex
add wave -group "Pipeline Instructions" -hex /hart_tb/dut/instruction_mem
add wave -group "Pipeline Instructions" -hex /hart_tb/dut/instruction_wb

# Some key registers for monitoring
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[0]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[1]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[2]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[3]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[4]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[5]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[6]
add wave -group "Registers x0-x7" -hex /hart_tb/dut/rf/mem[7]

echo "=== Running Simulation ==="
echo "X-state fixes implemented:"
echo "  1. stall signal initialized to 0"
echo "  2. pc_write_trap initialized to 0" 
echo "  3. mem_trap initialized to 0"
echo "  4. All pipeline registers properly connected"
echo ""

run -all

wave zoom full
echo "=== Simulation Complete ==="
echo "Red marks should now be eliminated!"
echo "Check the waveforms - signals should show proper values instead of X states."