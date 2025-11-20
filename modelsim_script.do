# ModelSim simulation script for HART processor
# Clean up previous simulation
quit -sim
file delete -force work
vlib work

# Compile all RTL files
echo "Compiling RTL files..."
vlog rtl/d_ff.v
vlog rtl/rf.v
vlog rtl/imm.v
vlog rtl/alu.v
vlog rtl/if_id_reg.v
vlog rtl/id_ex_reg.v
vlog rtl/ex_mem_reg.v
vlog rtl/mem_wb_reg.v
vlog rtl/fetch.v
vlog rtl/decode.v
vlog rtl/execute.v
vlog rtl/memory.v
vlog rtl/writeback.v
vlog rtl/hart.v

# Compile testbench
echo "Compiling testbench..."
vlog tb/tb.v

# Start simulation
echo "Starting simulation..."
vsim -t ps hart_tb

# Set up comprehensive waveforms
echo "Adding waves to monitor..."

# Add all top-level signals
add wave -group "Clock & Reset" sim:/hart_tb/clk
add wave -group "Clock & Reset" sim:/hart_tb/rst

# Instruction Memory Interface
add wave -group "Instruction Memory" -hex sim:/hart_tb/imem_raddr
add wave -group "Instruction Memory" -hex sim:/hart_tb/imem_rdata

# Data Memory Interface  
add wave -group "Data Memory" -hex sim:/hart_tb/dmem_addr
add wave -group "Data Memory" sim:/hart_tb/dmem_ren
add wave -group "Data Memory" sim:/hart_tb/dmem_wen
add wave -group "Data Memory" -hex sim:/hart_tb/dmem_wdata
add wave -group "Data Memory" -hex sim:/hart_tb/dmem_rdata
add wave -group "Data Memory" -bin sim:/hart_tb/dmem_mask

# Retirement Interface
add wave -group "Retire" sim:/hart_tb/valid
add wave -group "Retire" sim:/hart_tb/trap
add wave -group "Retire" sim:/hart_tb/halt
add wave -group "Retire" -hex sim:/hart_tb/inst
add wave -group "Retire" -hex sim:/hart_tb/pc
add wave -group "Retire" -hex sim:/hart_tb/next_pc

# Register File Access
add wave -group "Register Access" -unsigned sim:/hart_tb/rs1_raddr
add wave -group "Register Access" -hex sim:/hart_tb/rs1_rdata
add wave -group "Register Access" -unsigned sim:/hart_tb/rs2_raddr
add wave -group "Register Access" -hex sim:/hart_tb/rs2_rdata
add wave -group "Register Access" -unsigned sim:/hart_tb/rd_waddr
add wave -group "Register Access" -hex sim:/hart_tb/rd_wdata

# Pipeline Stages (IF/ID)
add wave -group "IF/ID Stage" -hex sim:/hart_tb/dut/if_id_pc
add wave -group "IF/ID Stage" -hex sim:/hart_tb/dut/if_id_inst
add wave -group "IF/ID Stage" sim:/hart_tb/dut/if_id_stall
add wave -group "IF/ID Stage" sim:/hart_tb/dut/if_id_flush

# Pipeline Stages (ID/EX) 
add wave -group "ID/EX Stage" -hex sim:/hart_tb/dut/id_ex_pc
add wave -group "ID/EX Stage" -hex sim:/hart_tb/dut/id_ex_inst
add wave -group "ID/EX Stage" -hex sim:/hart_tb/dut/id_ex_rs1_rdata
add wave -group "ID/EX Stage" -hex sim:/hart_tb/dut/id_ex_rs2_rdata
add wave -group "ID/EX Stage" -hex sim:/hart_tb/dut/id_ex_imm
add wave -group "ID/EX Stage" sim:/hart_tb/dut/id_ex_stall
add wave -group "ID/EX Stage" sim:/hart_tb/dut/id_ex_flush

# Pipeline Stages (EX/MEM)
add wave -group "EX/MEM Stage" -hex sim:/hart_tb/dut/ex_mem_pc
add wave -group "EX/MEM Stage" -hex sim:/hart_tb/dut/ex_mem_inst
add wave -group "EX/MEM Stage" -hex sim:/hart_tb/dut/ex_mem_alu_result
add wave -group "EX/MEM Stage" sim:/hart_tb/dut/ex_mem_stall
add wave -group "EX/MEM Stage" sim:/hart_tb/dut/ex_mem_flush

# Pipeline Stages (MEM/WB)
add wave -group "MEM/WB Stage" -hex sim:/hart_tb/dut/mem_wb_pc
add wave -group "MEM/WB Stage" -hex sim:/hart_tb/dut/mem_wb_inst
add wave -group "MEM/WB Stage" -hex sim:/hart_tb/dut/mem_wb_result
add wave -group "MEM/WB Stage" sim:/hart_tb/dut/mem_wb_stall

# Control Signals
add wave -group "Control" sim:/hart_tb/dut/decode_unit/alu_op
add wave -group "Control" sim:/hart_tb/dut/decode_unit/reg_write
add wave -group "Control" sim:/hart_tb/dut/decode_unit/mem_read
add wave -group "Control" sim:/hart_tb/dut/decode_unit/mem_write
add wave -group "Control" sim:/hart_tb/dut/decode_unit/branch
add wave -group "Control" sim:/hart_tb/dut/decode_unit/jump

# ALU Signals
add wave -group "ALU" -hex sim:/hart_tb/dut/execute_unit/alu_a
add wave -group "ALU" -hex sim:/hart_tb/dut/execute_unit/alu_b
add wave -group "ALU" -hex sim:/hart_tb/dut/execute_unit/alu_result
add wave -group "ALU" sim:/hart_tb/dut/execute_unit/alu_zero

# Register File (first 16 registers for monitoring)
for {set i 0} {$i < 16} {incr i} {
    add wave -group "Registers x0-x15" -hex sim:/hart_tb/dut/rf/mem($i)
}

# Hazard Detection & Forwarding (if implemented)
if {[find signals sim:/hart_tb/dut/*hazard*] != ""} {
    add wave -group "Hazard Control" sim:/hart_tb/dut/*hazard*
}

if {[find signals sim:/hart_tb/dut/*forward*] != ""} {
    add wave -group "Forwarding" sim:/hart_tb/dut/*forward*
}

# Configure wave window
wave zoom full
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1

# Run simulation
echo "Running simulation..."
run -all

echo "Simulation complete. Use 'wave zoom full' to see all waveforms."
echo "Use 'wave zoom range <start_time> <end_time>' to zoom to specific time range."