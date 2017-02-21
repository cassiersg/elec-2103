module mtl_touch_ip (
    // Clock and reset
    input   logic           clk,
    input   logic           reset,
    
    // Avalon MM interface
    input   logic [4:0]     avs_s0_address,
    output  logic [31:0]    avs_s0_readdata,
    
    // MTL connection
    output  logic           MTL_TOUCH_I2C_SCL,  // I2C clock pin of Touch IC (from MTL)
    inout                   MTL_TOUCH_I2C_SDA,  // I2C data pin of Touch IC (from/to MTL)
    input                   MTL_TOUCH_INT_n     // Interrupt pin of Touch IC (from MTL)
);

// Resgisters for synchronizing touch signals
logic [31:0]    x1_reg, x2_reg, x3_reg, x4_reg, x5_reg;
logic [31:0]    y1_reg, y2_reg, y3_reg, y4_reg, y5_reg;
logic [7:0]     gesture_reg;
logic [31:0]    touch_count_reg;
logic           touch_ready_reg;

// Instantiation of the touch controller
logic [9:0]     x1, x2, x3, x4, x5;
logic [8:0]     y1, y2, y3, y4, y5;
logic [7:0]     gesture;
logic [3:0]     touch_count;
logic           touch_ready;

mtl_touch_controller mtl_touch_controller_inst (
    .iCLK(clk),
    .iRST(reset),
    .MTL_TOUCH_INT_n(MTL_TOUCH_INT_n),
    .MTL_TOUCH_I2C_SDA(MTL_TOUCH_I2C_SDA),
    .MTL_TOUCH_I2C_SCL(MTL_TOUCH_I2C_SCL),
    .reg_x1(x1),
    .reg_x2(x2),
    .reg_x3(x3),
    .reg_x4(x4),
    .reg_x5(x5),
    .reg_y1(y1),
    .reg_y2(y2),
    .reg_y3(y3),
    .reg_y4(y4),
    .reg_y5(y5),
    .reg_touch_count(touch_count),
    .reg_gesture(gesture),
    .touch_ready(touch_ready)
);

// Update registers only when touch_ready == 1
always_ff @(posedge clk)
begin
    if (reset)
    begin
        x1_reg          <= 32'b0;
        x2_reg          <= 32'b0;
        x3_reg          <= 32'b0;
        x4_reg          <= 32'b0;
        x5_reg          <= 32'b0;
        
        y1_reg          <= 32'b0;
        y2_reg          <= 32'b0;
        y3_reg          <= 32'b0;
        y4_reg          <= 32'b0;
        y5_reg          <= 32'b0;
        
        gesture_reg     <= 8'b0;
        touch_count_reg <= 32'b0;
        touch_ready_reg <= 1'b0;
    end
    else if (touch_ready)
    begin
        x1_reg          <= x1;
        x2_reg          <= x2;
        x3_reg          <= x3;
        x4_reg          <= x4;
        x5_reg          <= x5;
        
        y1_reg          <= y1;
        y2_reg          <= y2;
        y3_reg          <= y3;
        y4_reg          <= y4;
        y5_reg          <= y5;
        
        gesture_reg     <= gesture;
        touch_count_reg <= touch_count;
        touch_ready_reg <= touch_ready;
    end
end

// Set readdata
always_comb
case (avs_s0_address[4:0])
    5'h0:   avs_s0_readdata = x1_reg;
    5'h1:   avs_s0_readdata = x2_reg;
    5'h2:   avs_s0_readdata = x3_reg;
    5'h3:   avs_s0_readdata = x4_reg;
    5'h4:   avs_s0_readdata = x5_reg;
    
    5'h8:   avs_s0_readdata = y1_reg;
    5'h9:   avs_s0_readdata = y2_reg;
    5'ha:   avs_s0_readdata = y3_reg;
    5'hb:   avs_s0_readdata = y4_reg;
    5'hc:   avs_s0_readdata = y5_reg;
    
    5'h10:  avs_s0_readdata = touch_count_reg;
    5'h11:  avs_s0_readdata = gesture_reg;
    5'h12:  avs_s0_readdata = touch_ready_reg;
    
    default:	avs_s0_readdata = 32'b0;
endcase

endmodule
