# Simple ModelSim setup script - run this in ModelSim GUI
# This script assumes you're already in the correct directory

# Clean workspace
if {[file exists work]} {
    file delete -force work
}
vlib work

# Compile RTL files in dependency order
puts "Compiling RTL files..."
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
vlog tb/tb.v

# Start simulation
puts "Starting simulation of hart_tb..."
vsim hart_tb

# Basic waveforms - you can add more as needed
add wave sim:/hart_tb/clk
add wave sim:/hart_tb/rst
add wave -hex sim:/hart_tb/pc
add wave -hex sim:/hart_tb/inst
add wave -hex sim:/hart_tb/imem_raddr
add wave -hex sim:/hart_tb/imem_rdata
add wave sim:/hart_tb/valid
add wave sim:/hart_tb/halt

# Run for a reasonable time
run 10us

puts "Basic simulation setup complete. Add more waves as needed and continue with 'run -all'"