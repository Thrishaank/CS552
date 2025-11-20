# ModelSim compilation check script
# Run this to check for compilation errors without GUI

# Clean up
if {[file exists work]} {
    file delete -force work  
}
vlib work

# Set error handling
onerror {resume}

# Compile RTL files
puts "=== Compiling RTL Files ==="
puts "Compiling d_ff.v..."
vlog rtl/d_ff.v
if {$errorCode != ""} {puts "ERROR in d_ff.v"; exit 1}

puts "Compiling rf.v..."  
vlog rtl/rf.v
if {$errorCode != ""} {puts "ERROR in rf.v"; exit 1}

puts "Compiling imm.v..."
vlog rtl/imm.v  
if {$errorCode != ""} {puts "ERROR in imm.v"; exit 1}

puts "Compiling alu.v..."
vlog rtl/alu.v
if {$errorCode != ""} {puts "ERROR in alu.v"; exit 1}

puts "Compiling pipeline registers..."
vlog rtl/if_id_reg.v
if {$errorCode != ""} {puts "ERROR in if_id_reg.v"; exit 1}

vlog rtl/id_ex_reg.v  
if {$errorCode != ""} {puts "ERROR in id_ex_reg.v"; exit 1}

vlog rtl/ex_mem_reg.v
if {$errorCode != ""} {puts "ERROR in ex_mem_reg.v"; exit 1}

vlog rtl/mem_wb_reg.v
if {$errorCode != ""} {puts "ERROR in mem_wb_reg.v"; exit 1}

puts "Compiling pipeline stages..."
vlog rtl/fetch.v
if {$errorCode != ""} {puts "ERROR in fetch.v"; exit 1}

vlog rtl/decode.v
if {$errorCode != ""} {puts "ERROR in decode.v"; exit 1}

vlog rtl/execute.v  
if {$errorCode != ""} {puts "ERROR in execute.v"; exit 1}

vlog rtl/memory.v
if {$errorCode != ""} {puts "ERROR in memory.v"; exit 1}

vlog rtl/writeback.v
if {$errorCode != ""} {puts "ERROR in writeback.v"; exit 1}

puts "Compiling top module..."
vlog rtl/hart.v
if {$errorCode != ""} {puts "ERROR in hart.v"; exit 1}

puts "Compiling testbench..."
vlog tb/tb.v
if {$errorCode != ""} {puts "ERROR in tb.v"; exit 1}

puts "=== COMPILATION SUCCESSFUL ==="
puts "All files compiled successfully!"
puts "You can now run: vsim hart_tb"

exit 0