	component qsys1 is
		port (
			clk_clk                                   : in    std_logic := 'X'; -- clk
			mtl_touch_ip_0_mtl_connection_i2cclock    : out   std_logic;        -- i2cclock
			mtl_touch_ip_0_mtl_connection_interruptic : in    std_logic := 'X'; -- interruptic
			mtl_touch_ip_0_mtl_connection_i2cdata     : inout std_logic := 'X'; -- i2cdata
			reset_reset_n                             : in    std_logic := 'X'  -- reset_n
		);
	end component qsys1;

	u0 : component qsys1
		port map (
			clk_clk                                   => CONNECTED_TO_clk_clk,                                   --                           clk.clk
			mtl_touch_ip_0_mtl_connection_i2cclock    => CONNECTED_TO_mtl_touch_ip_0_mtl_connection_i2cclock,    -- mtl_touch_ip_0_mtl_connection.i2cclock
			mtl_touch_ip_0_mtl_connection_interruptic => CONNECTED_TO_mtl_touch_ip_0_mtl_connection_interruptic, --                              .interruptic
			mtl_touch_ip_0_mtl_connection_i2cdata     => CONNECTED_TO_mtl_touch_ip_0_mtl_connection_i2cdata,     --                              .i2cdata
			reset_reset_n                             => CONNECTED_TO_reset_reset_n                              --                         reset.reset_n
		);

