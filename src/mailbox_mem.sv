module mailbox_mem(
	input logic clk,
	input logic reset,

	input logic [4:0] avs_s0_address,
	input logic [31:0] avs_s0_writedata,
	output logic [31:0] avs_s0_readdata,
	input logic avs_s0_write,
	input logic avs_s0_read,
	
	input logic [4:0] avs_s1_address,
	input logic [31:0] avs_s1_writedata,
	output logic [31:0] avs_s1_readdata,
	input logic avs_s1_write,
	input logic avs_s1_read
);

logic [31:0] RAM [3:0];
logic fresh [3:0];

logic [3:0] base_addr_s0;
logic addr_in_fresh_s0;
assign base_addr_s0 = avs_s0_address[3:0];
assign addr_in_fresh_s0 = avs_s0_address[4];

always_ff @(posedge clk)
begin
	if (avs_s0_write && ~addr_in_fresh_s0)
	begin
		RAM[base_addr_s0] <= avs_s0_writedata;
		fresh[base_addr_s0] <= 1'b1;
	end
	else if (avs_s0_read && ~addr_in_fresh_s0)
	begin
		fresh[base_addr_s0] <= 1'b0;
	end
end

always_comb
begin
	if (addr_in_fresh_s0) avs_s0_readdata = {31'b0, fresh[base_addr_s0]};
	else avs_s0_readdata = RAM[base_addr_s0];
end


logic [3:0] base_addr_s1;
logic addr_in_fresh_s1;
assign base_addr_s1 = avs_s1_address[3:0];
assign addr_in_fresh_s1 = avs_s1_address[4];

always_ff @(posedge clk)
begin
	if (avs_s1_write && ~addr_in_fresh_s1)
	begin
		RAM[base_addr_s1] <= avs_s1_writedata;
		fresh[base_addr_s1] <= 1'b1;
	end
	else if (avs_s1_read && ~addr_in_fresh_s1)
	begin
		fresh[base_addr_s1] <= 1'b0;
	end
end

always_comb
begin
	if (addr_in_fresh_s1) avs_s1_readdata = {31'b0, fresh[base_addr_s1]};
	else avs_s1_readdata = RAM[base_addr_s1];
end

endmodule
