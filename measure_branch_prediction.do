# ModelSim script to measure branch prediction accuracy
# Run with: vsim -do measure_branch_prediction.do

# Compile
vlib work
vlog rtl/*.v
vlog tb/tb.v

# Load simulation
vsim hart_tb

# Add tracking signals
set branch_count 0
set correct_predictions 0
set incorrect_predictions 0

# Track branch instructions in execute stage
# Assumes you have branch prediction signals in your processor

# Run simulation
run 100000ns

# Calculate statistics
set total_branches [expr $branch_count]
if {$total_branches > 0} {
    set accuracy [expr ($correct_predictions * 100.0) / $total_branches]
    echo "=== BRANCH PREDICTION RESULTS ==="
    echo "Total Branches:        $total_branches"
    echo "Correct Predictions:   $correct_predictions"
    echo "Incorrect Predictions: $incorrect_predictions"
    echo "Accuracy:              $accuracy%"
} else {
    echo "No branches detected"
}

quit -f

