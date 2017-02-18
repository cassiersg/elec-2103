
module mtl_touch_ip (
    // Clock
    input logic clk,
    // Reset
    input logic reset,
    // Avalon MM interface
    input logic [4:0] avs_s0_address,
    output logic [31:0] avs_s0_readdata,
    // MTL connection
    output logic MTL_TOUCH_I2C_SCL, // I2C clock pin of Touch IC (from MTL)
    inout MTL_TOUCH_I2C_SDA, // I2C data pin of Touch IC (from/to MTL)
    input MTL_TOUCH_INT_n // Interrupt pin of Touch IC (from MTL)
);

// Resgisters for synchronizing touch signals
logic [9:0] x_regs [4:0];
logic [8:0] y_regs [4:0];
logic [7:0] gesture_reg;
logic [3:0] touch_count_reg;

// Instantiation of the touch controller
logic [9:0] x [4:0];
logic [8:0] y [4:0];
logic [7:0] gesture;
logic [3:0] touch_count;
logic touch_ready;
mtl_touch_controller mtl_touch_controller_inst (
    .iCLK(clk),
    .iRST(reset),
    // MTL TOUCH
    .MTL_TOUCH_INT_n(MTL_TOUCH_INT_n), // Interrupt pin of Touch IC (from MTL)
    .MTL_TOUCH_I2C_SDA(MTL_TOUCH_I2C_SDA), // I2C data pin of Touch IC (from/to MTL)
    .MTL_TOUCH_I2C_SCL(MTL_TOUCH_I2C_SCL), // I2C clock pin of Touch IC (from MTL)
    // Gestures not used
    .reg_x1(x[0]),
    .reg_x2(x[1]),
    .reg_x3(x[2]),
    .reg_x4(x[3]),
    .reg_x5(x[4]),
    .reg_y1(y[0]),
    .reg_y2(y[1]),
    .reg_y3(y[2]),
    .reg_y4(y[3]),
    .reg_y5(y[4]),
    .reg_touch_count(touch_count),
    .reg_gesture(gesture),
    .touch_ready(touch_ready)
);

// Update registers only when touch_ready == 1
always_ff @(posedge clk)
begin
    if (reset)
    begin
        x_regs <= '{5{10'b0}};
        y_regs <= '{5{9'b0}};
        gesture_reg <= 8'b0;
        touch_count_reg <= 4'b0;
    end
    else if (touch_ready)
    begin
        x_regs <= x;
        y_regs <= y;
        gesture_reg <= gesture;
        touch_count_reg <= touch_count;
    end
end

// Set readdata
always_comb
case (avs_s0_address[4:3])
    2'h0:
    begin
        if (avs_s0_address[2:0] <= 3'h5)
            avs_s0_readdata = x_regs[avs_s0_address[2:0]];
        else
            avs_s0_readdata = 32'b0;
    end
    2'h1:
    begin
        if (avs_s0_address[2:0] <= 3'h5)
            avs_s0_readdata = y_regs[avs_s0_address[2:0]];
        else
            avs_s0_readdata = 32'b0;
    end
    2'h2:
    begin
        if (avs_s0_address[2:0] == 3'h0)
            avs_s0_readdata = touch_count_reg;
        else if (avs_s0_address[2:0] == 3'h1)
            avs_s0_readdata = gesture_reg;
        else
            avs_s0_readdata = 32'b0;
    end
    2'h3: avs_s0_readdata = 32'b0;
endcase

endmodule
