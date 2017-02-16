	component base is
		port (
			clk_clk                          : in    std_logic                     := 'X';             -- clk
			pio_0_external_connection_export : in    std_logic_vector(31 downto 0) := (others => 'X'); -- export
			reset_reset_n                    : in    std_logic                     := 'X';             -- reset_n
			mtl_touch_conduit_i2c_scl        : out   std_logic;                                        -- i2c_scl
			mtl_touch_conduit_i2c_sda        : inout std_logic                     := 'X';             -- i2c_sda
			mtl_touch_conduit_touch_int_n    : in    std_logic                     := 'X'              -- touch_int_n
		);
	end component base;

	u0 : component base
		port map (
			clk_clk                          => CONNECTED_TO_clk_clk,                          --                       clk.clk
			pio_0_external_connection_export => CONNECTED_TO_pio_0_external_connection_export, -- pio_0_external_connection.export
			reset_reset_n                    => CONNECTED_TO_reset_reset_n,                    --                     reset.reset_n
			mtl_touch_conduit_i2c_scl        => CONNECTED_TO_mtl_touch_conduit_i2c_scl,        --         mtl_touch_conduit.i2c_scl
			mtl_touch_conduit_i2c_sda        => CONNECTED_TO_mtl_touch_conduit_i2c_sda,        --                          .i2c_sda
			mtl_touch_conduit_touch_int_n    => CONNECTED_TO_mtl_touch_conduit_touch_int_n     --                          .touch_int_n
		);

