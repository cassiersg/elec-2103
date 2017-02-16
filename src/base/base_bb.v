
module base (
	clk_clk,
	pio_0_external_connection_export,
	reset_reset_n,
	mtl_touch_conduit_i2c_scl,
	mtl_touch_conduit_i2c_sda,
	mtl_touch_conduit_touch_int_n);	

	input		clk_clk;
	input	[31:0]	pio_0_external_connection_export;
	input		reset_reset_n;
	output		mtl_touch_conduit_i2c_scl;
	inout		mtl_touch_conduit_i2c_sda;
	input		mtl_touch_conduit_touch_int_n;
endmodule
