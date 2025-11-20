# Minimal ModelSim script with only essential signals
quit -sim
file delete -force work
vlib work

# Compile RTL files
vlog rtl/d_ff.v rtl/rf.v rtl/imm.v rtl/alu.v
vlog rtl/if_id_reg.v rtl/id_ex_reg.v rtl/ex_mem_reg.v rtl/mem_wb_reg.v  
vlog rtl/fetch.v rtl/decode.v rtl/execute.v rtl/memory.v rtl/writeback.v
vlog rtl/hart.v tb/tb.v

# Start simulation
vsim hart_tb

# Add essential signals only
add wave sim:/hart_tb/clk
add wave sim:/hart_tb/rst
add wave -hex sim:/hart_tb/pc
add wave -hex sim:/hart_tb/inst
add wave sim:/hart_tb/valid
add wave sim:/hart_tb/halt
add wave -hex sim:/hart_tb/imem_raddr
add wave -hex sim:/hart_tb/imem_rdata

# Memory interface
add wave -hex sim:/hart_tb/dmem_addr  
add wave sim:/hart_tb/dmem_ren
add wave sim:/hart_tb/dmem_wen
add wave -hex sim:/hart_tb/dmem_wdata
add wave -hex sim:/hart_tb/dmem_rdata

# Register file access
add wave -unsigned sim:/hart_tb/rd_waddr
add wave -hex sim:/hart_tb/rd_wdata

# Configure and run
wave zoom full
run -all

echo "Essential signals added. Simulation complete."