# Clean compilation script for hart with caches

# Quit any existing simulation
quit -sim

# Delete and recreate work library
if {[file exists work]} {
    vdel -all
}
vlib work

# Compile all RTL files in order
vlog -work work rtl/d_ff.v
vlog -work work rtl/imm.v
vlog -work work rtl/rf.v
vlog -work work rtl/alu.v
vlog -work work rtl/fetch.v
vlog -work work rtl/decode.v
vlog -work work rtl/execute.v
vlog -work work rtl/memory.v
vlog -work work rtl/writeback.v
vlog -work work rtl/if_id_reg.v
vlog -work work rtl/id_ex_reg.v
vlog -work work rtl/ex_mem_reg.v
vlog -work work rtl/mem_wb_reg.v
vlog -work work rtl/cache.v
vlog -work work rtl/hart.v

# Compile testbench
vlog -work work tb/tb.v

echo "Compilation complete. Work library rebuilt from scratch."

