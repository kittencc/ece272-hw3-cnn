run_c: compile_c
	./conv_gold

compile_c: conv_gold.cpp conv_gold_test.cpp
	g++ -g -std=c++11 conv_gold_test.cpp -o conv_gold

run_tb: compile_tb
	./simv

compile_tb: tests/conv_tb.sv verilog/conv.sv conv_gold.cpp
	vcs -full64 \
		-sverilog \
		-timescale=1ns/1ps \
		-debug_access+pp \
		-lca \
		-cflags "-std=c++11" \
		+vc+abstract \
		tests/conv_tb.sv \
		verilog/conv.sv \
		conv_gold_sv.cpp \
		| tee output.log

compile_tb_cc: tests/simple_tb_3.sv verilog/conv_tiled.v verilog/main_FSM.v verilog/accum_out_skew_fifo.v verilog/mac_more.v verilog/en_weight_shifter.v verilog/wrapped_skew_fifo.v verilog/input_skew_fifos.v verilog/fifo.v verilog/SizedFIFO.v verilog/mac_array.v verilog/mac.v verilog/weight_input_controller.v verilog/weight_addr_gen.v verilog/ofmap_output_controller.v verilog/ofmap_FSM.v verilog/ofmap_PISO.v verilog/accum_double_buffer.v verilog/accum_addr_gen.v verilog/ifmap_input_controller.v verilog/ifmap_input_FSM.v verilog/double_buffer.v verilog/input_write_addr_gen.v verilog/input_read_addr_gen.v verilog/input_chaining.v verilog/ff.v verilog/counter.v verilog/mux2.v verilog/ram_sync_1r1w.v 
	vcs -full64 \
		-sverilog \
		-timescale=1ns/1ps \
		-kdb \
		-debug_access+all \
		-lca \
		-cflags "-std=c++11" \
		+vc+abstract \
		tests/simple_tb_3.sv \
		verilog/conv_tiled.v \
		verilog/main_FSM.v \
		verilog/accum_out_skew_fifo.v \
		verilog/mac_more.v \
		verilog/en_weight_shifter.v \
	  verilog/wrapped_skew_fifo.v \
		verilog/input_skew_fifos.v \
		verilog/fifo.v \
		verilog/SizedFIFO.v \
		verilog/mac_array.v  \
		verilog/mac.v \
		verilog/weight_input_controller.v \
	  verilog/weight_addr_gen.v  \
	  verilog/ofmap_output_controller.v \
		verilog/ofmap_FSM.v \
		verilog/ofmap_PISO.v  \
	  verilog/accum_double_buffer.v \
	  verilog/accum_addr_gen.v  \
	  verilog/ifmap_input_controller.v \
		verilog/ifmap_input_FSM.v \
		verilog/double_buffer.v  \
		verilog/input_write_addr_gen.v \
		verilog/input_read_addr_gen.v \
		verilog/input_chaining.v \
    verilog/ff.v \
    verilog/counter.v \
		verilog/mux2.v  \
	  verilog/ram_sync_1r1w.v  \
	  conv_gold_sv.cpp \
		| tee output.log



debug: compile_tb
	./simv	
	dve -full64 -vpd dump.vcd &

debug_cc: compile_tb_cc
	./simv	
	verdi -ssf dump.fsbd &



clean:
	rm -rf ./conv_gold
	rm -rf ./simv
	rm -rf simv.daidir/ 
	rm -rf *.vcd
	rm -rf csrc
	rm -rf ucli.key
	rm -rf output.log
	rm -rf vc_hdrs.h
	rm -rf DVEfiles
