vlib work
vmap work work
vlog +acc rtl/*.v
vsim -voptargs=+acc work.tb_digital_lock
add wave -r sim:/tb_digital_lock/*
add wave -r sim:/tb_digital_lock/dut/*
radix unsigned
run -all
