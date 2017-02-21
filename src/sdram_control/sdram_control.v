// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	Sdram Control Multi-Port
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny Fan        :| 08/04/22  :| Initial Revision
//   V2.0 :| Charlotte Frenkel :| 14/08/03  :| Improved and modified for
//															  adaptation from the DE2 SDRAM 
// 														  to the DE0-Nano SDRAM
// --------------------------------------------------------------------
//

module sdram_control (
    //	HOST Side
    RESET_N,
	CLK,
	
    //	FIFO Write Side 1
    WR1_DATA,
	WR1,
	WR1_ADDR,
	WR1_MAX_ADDR,
	WR1_LENGTH,
	WR1_LOAD,
	WR1_CLK,
	
    //	FIFO Write Side 2
    WR2_DATA,
	WR2,
	WR2_ADDR,
	WR2_MAX_ADDR,
	WR2_LENGTH,
	WR2_LOAD,
	WR2_CLK,
	
    //	FIFO Read Side 1
    RD1_DATA,
	RD1,
	RD1_ADDR,
	RD1_MAX_ADDR,
	RD1_LENGTH,
	RD1_LOAD,
	RD1_CLK,
	
    //	FIFO Read Side 2
    RD2_DATA,
	RD2,
	RD2_ADDR,
	RD2_MAX_ADDR,
	RD2_LENGTH,
	RD2_LOAD,
	RD2_CLK,
	
    //	SDRAM Side
    SA,
    BA,
    CS_N,
    CKE,
    RAS_N,
    CAS_N,
    WE_N,
    DQ,
    DQM
);

//=======================================================
//  PARAMETER declarations
//=======================================================
`include  "sdram_params.h"

//=======================================================
//  PORT declarations
//=======================================================
//	HOST Side
input                   RESET_N;        // System Reset
input                   CLK;
//	FIFO Write Side 1
input   [`DIOSIZE-1:0]  WR1_DATA;       // Data Input
input                   WR1;            // Write Request
input   [`ASIZE-1:0]    WR1_ADDR;		// Write Start Address
input   [`ASIZE-1:0]    WR1_MAX_ADDR;	// Write Max Address
input	[8:0]           WR1_LENGTH;     // Write Length
input                   WR1_LOAD;		// Write FIFO Clear
input                   WR1_CLK;		// Write FIFO Clock
//	FIFO Write Side 2
input   [`DIOSIZE-1:0]  WR2_DATA;       // Data Input
input                   WR2;			// Write Request
input   [`ASIZE-1:0]    WR2_ADDR;		// Write Start Address
input   [`ASIZE-1:0]    WR2_MAX_ADDR;	// Write Max Address
input   [8:0]           WR2_LENGTH;     // Write Length
input                   WR2_LOAD;		// Write FIFO Clear
input                   WR2_CLK;		// Write FIFO Clock
//	FIFO Read Side 1
output  [`DIOSIZE-1:0]  RD1_DATA;       // Data Output
input                   RD1;            // Read Request
input   [`ASIZE-1:0]    RD1_ADDR;		// Read Start Address
input   [`ASIZE-1:0]    RD1_MAX_ADDR;	// Read Max Address
input   [8:0]           RD1_LENGTH;		// Read Length
input                   RD1_LOAD;		// Read FIFO Clear
input                   RD1_CLK;		// Read FIFO Clock
//	FIFO Read Side 2
output  [`DIOSIZE-1:0]  RD2_DATA;       // Data Output
input                   RD2;            // Read Request
input   [`ASIZE-1:0]    RD2_ADDR;       // Read Start Address
input   [`ASIZE-1:0]    RD2_MAX_ADDR;   // Read Max Address
input   [8:0]           RD2_LENGTH;		// Read Length
input                   RD2_LOAD;		// Read FIFO Clear
input                   RD2_CLK;		// Read FIFO Clock
//	SDRAM Side
output  [12:0]          SA;             // SDRAM address output
output  [1:0]           BA;             // SDRAM bank address
output                  CS_N;           // SDRAM Chip Select
output                  CKE;            // SDRAM clock enable
output                  RAS_N;          // SDRAM Row address Strobe
output                  CAS_N;          // SDRAM Column address Strobe
output                  WE_N;           // SDRAM write enable
inout   [`DSIZE-1:0]    DQ;             // SDRAM data bus
output  [`DSIZE/8-1:0]  DQM;            // SDRAM data mask lines

//=======================================================
//  Signal Declarations
//=======================================================
//	Controller
reg	    [`ASIZE-1:0]    mADDR;					                //Internal address
reg	    [8:0]           mLENGTH;				                //Internal length
wire                    WR1_DONE, WR2_DONE, RD1_DONE, RD2_DONE;
reg	    [`ASIZE-1:0]    rWR1_ADDR, rWR2_ADDR;		            //Register write address		
reg		[`ASIZE-1:0]    rWR1_MAX_ADDR, rWR2_MAX_ADDR;           //Register max write address		
reg	    [`ASIZE-1:0]    rRD1_ADDR, rRD2_ADDR;		            //Register read address
reg		[`ASIZE-1:0]    rRD1_MAX_ADDR, rRD2_MAX_ADDR;           //Register max read address		
reg		[1:0] WR_MASK;			                                //Write port active mask
reg		[1:0] RD_MASK;			                                //Read port active mask
reg				        mWR_DONE;				                //Flag write done, 1 pulse SDR_CLK
reg				        mRD_DONE;				                //Flag read done, 1 pulse SDR_CLK
reg				        mWR,Pre_WR;			                    //Internal WR edge capture
reg				        mRD,Pre_RD;			                    //Internal RD edge capture
reg 	[9:0] ST;					                            //Controller status
reg	    [1:0] CMD;				            	                //Controller command
reg				        PM_STOP;			         	        //Flag page mode stop
reg				        PM_DONE;			         	        //Flag page mode done
reg				        Read;				         	        //Flag read active
reg			            Write;			          		        //Flag write active
reg     [`DSIZE-1:0]    mDATAOUT;                		        //Controller Data output 
wire    [`DSIZE-1:0]    mDATAIN;                 		        //Controller Data input
wire    [`DSIZE-1:0]    mDATAIN1;                		        //Controller Data input 1
wire    [`DSIZE-1:0]    mDATAIN2;                		        //Controller Data input 2
wire                    CMDACK;    		                        //Controller command acknowledgement

//	DRAM Control                
reg     [`DSIZE/8-1:0]  DQM;                // SDRAM data mask lines
reg     [12:0]          SA;                 // SDRAM address output
reg     [1:0]           BA;                 // SDRAM bank address
reg                     CS_N;               // SDRAM Chip Select
reg                     CKE;                // SDRAM clock enable
reg                     RAS_N;              // SDRAM Row address Strobe
reg                     CAS_N;              // SDRAM Column address Strobe
reg                     WE_N;               // SDRAM write enable
wire    [`DSIZE-1:0]    DQOUT;              // SDRAM data out link
wire    [`DSIZE/8-1:0]  IDQM;               // SDRAM data mask lines
wire    [12:0]          ISA;                // SDRAM address output
wire    [1:0]           IBA;                // SDRAM bank address
wire                    ICS_N;              // SDRAM Chip Select
wire                    ICKE;               // SDRAM clock enable
wire                    IRAS_N;             // SDRAM Row address Strobe
wire                    ICAS_N;             // SDRAM Column address Strobe
wire                    IWE_N;              // SDRAM write enable

//	FIFO Control                           
reg					    OUT_VALID;		    // Output data request to read side fifo
reg					    IN_REQ;			    // Input	data request to write side fifo
wire    [8:0]           write_side_fifo_rusedw1, write_side_fifo_rusedw2;
wire    [8:0]           read_side_fifo_wusedw1, read_side_fifo_wusedw2;
wire    [10:0]          rd1_ram_wraddr, rd2_ram_wraddr;
wire    [9:0]           rd1_ram_rdaddr, rd2_ram_rdaddr;
wire                    rd1_req, rd2_req;

//	DRAM Internal Control
wire    [`ASIZE-1:0]    saddr;
wire                    load_mode;
wire                    nop;
wire                    reada;
wire                    writea;
wire                    refresh;
wire                    precharge;
wire                    oe;
wire                    ref_ack;
wire                    ref_req;
wire                    init_req;
wire				    cm_ack;
wire				    active;

//=======================================================
//  Sub-module
//=======================================================
control_interface  u_control_interface (
        .CLK(CLK),
        .RESET_N(RESET_N),
        .CMD(CMD),
        .ADDR(mADDR),
        .REF_ACK(ref_ack),
        .CM_ACK(cm_ack),
        .NOP(nop),
        .READA(reada),
        .WRITEA(writea),
        .REFRESH(refresh),
        .PRECHARGE(precharge),
        .LOAD_MODE(load_mode),
        .SADDR(saddr),
        .REF_REQ(ref_req),
		.INIT_REQ(init_req),
        .CMD_ACK(CMDACK)
);

command  u_command (
        .CLK(CLK),
        .RESET_N(RESET_N),
        .SADDR(saddr),
        .NOP(nop),
        .READA(reada),
        .WRITEA(writea),
        .REFRESH(refresh),
		.LOAD_MODE(load_mode),
        .PRECHARGE(precharge),
        .REF_REQ(ref_req),
		.INIT_REQ(init_req),
        .REF_ACK(ref_ack),
        .CM_ACK(cm_ack),
        .OE(oe),
		.PM_STOP(PM_STOP),
		.PM_DONE(PM_DONE),
        .SA(ISA),
        .BA(IBA),
        .CS_N(ICS_N),
        .CKE(ICKE),
        .RAS_N(IRAS_N),
        .CAS_N(ICAS_N),
        .WE_N(IWE_N)
);
                
sdr_data_path  u_sdr_data_path (
        .CLK(CLK),
        .RESET_N(RESET_N),
        .DATAIN(mDATAIN),
        .DM(2'b00),
        .DQOUT(DQOUT),
        .DQM(IDQM)
);

/* 
======================
    FIFO ARE HERE
======================
*/

Sdram_WR_FIFO  u_write1_fifo (
		.data(WR1_DATA),
		.wrreq(WR1),
		.wrclk(WR1_CLK),
		.aclr(WR1_LOAD),
		.rdreq(IN_REQ&&WR_MASK[0]),
		.rdclk(CLK),
		.q(mDATAIN1),
		.rdusedw(write_side_fifo_rusedw1)
);

Sdram_WR_FIFO  u_write2_fifo (
		.data(WR2_DATA),
		.wrreq(WR2),
		.wrclk(WR2_CLK),
		.aclr(WR2_LOAD),
		.rdreq(IN_REQ&&WR_MASK[1]),
		.rdclk(CLK),
		.q(mDATAIN2),
		.rdusedw(write_side_fifo_rusedw2)
);
			
Sdram_RD_FIFO  u_read1_fifo (
		.data(mDATAOUT),
		.wrreq(OUT_VALID&RD_MASK[0]),
		.wrclk(CLK),
		.aclr(RD1_LOAD),
		.rdreq(RD1),
		.rdclk(RD1_CLK),
		.q(RD1_DATA),
		.wrusedw(read_side_fifo_wusedw1)
);
	
Sdram_RD_FIFO  u_read2_fifo (
		.data(mDATAOUT),
		.wrreq(OUT_VALID&RD_MASK[1]),
		.wrclk(CLK),
		.aclr(RD2_LOAD),
		.rdreq(RD2),
		.rdclk(RD2_CLK),
		.q(RD2_DATA),
		.wrusedw(read_side_fifo_wusedw2)
);

//=======================================================
//  Structural coding
//=======================================================
assign mDATAIN  = (WR_MASK[0]) ? mDATAIN1 : mDATAIN2;
assign DQ       = oe ? DQOUT : `DSIZE'hzzzzzzzz;
assign active	= Read | Write;

assign WR1_DONE = mWR_DONE&&WR_MASK[0]; 
assign WR2_DONE = mWR_DONE&&WR_MASK[1]; 
assign RD1_DONE = mRD_DONE&&RD_MASK[0]; 
assign RD2_DONE = mRD_DONE&&RD_MASK[1];

always @ (posedge CLK)
begin
	SA       <= (ST==SC_CL+mLENGTH) ? 13'h200	:	ISA;
   BA       <= IBA;
   CS_N     <= ICS_N;
   CKE      <= ICKE;
   RAS_N    <= (ST==SC_CL+mLENGTH) ? 1'b0 : IRAS_N;
   CAS_N    <= (ST==SC_CL+mLENGTH) ? 1'b1 : ICAS_N;
   WE_N     <= (ST==SC_CL+mLENGTH) ? 1'b0 : IWE_N;
	PM_STOP	<= (ST==SC_CL+mLENGTH) ? 1'b1 : 1'b0;
	PM_DONE	<= (ST==SC_CL+SC_RCD+mLENGTH+2)	?	1'b1 : 1'b0;
	DQM		<= (active && (ST>=SC_CL) )	 ? (((ST==SC_CL+mLENGTH) && Write)?	4'b1111	:	4'b0	)	:	4'b1111;
	mDATAOUT <= DQ;
end

always@(posedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		CMD		  <= 0;
		ST			  <= 0;
		Pre_RD	  <= 0;
		Pre_WR	  <= 0;
		Read		  <= 0;
		Write		  <= 0;
		OUT_VALID  <= 0;
		IN_REQ	  <= 0;
		mWR_DONE	  <= 0;
		mRD_DONE	  <= 0;
	end
	else
	begin
		Pre_RD	<=	mRD;
		Pre_WR	<=	mWR;
		case (ST)
		0:	begin
				if (!Pre_RD && mRD)
				begin
					Read	<=	1;
					Write	<=	0;
					CMD		<=	2'b01;
					ST		<=	1;
				end
				else if (!Pre_WR && mWR)
				begin
					Read	<=	0;
					Write	<=	1;
					CMD		<=	2'b10;
					ST		<=	1;
				end
		end
		1:	begin
				if (CMDACK)
				begin
					CMD   <=  2'b00;
					ST    <=  2;
				end
		end
		default:  begin	
				if (ST!=SC_CL+SC_RCD+mLENGTH+1) ST <= ST+1;
				else ST    <=  0;
		end
		endcase
	
		if (Read)
		begin
			if (ST==SC_CL+SC_RCD+1) OUT_VALID <= 1;
			else if (ST==SC_CL+SC_RCD+mLENGTH+1)
			begin
				OUT_VALID	<=	0;
				Read		  <=	0;
				mRD_DONE	<=	1;
			end
		end
		else mRD_DONE<= 0;
		
		if (Write)
		begin
			if (ST==SC_CL-1) IN_REQ <= 1;
			else if (ST==SC_CL+mLENGTH-1) IN_REQ <= 0;
			else if (ST==SC_CL+SC_RCD+mLENGTH)
			begin
				Write 	<=	0;
				mWR_DONE<=	1;
			end
		end
		else mWR_DONE  <=	0;
	end
end

//	Internal Address & Length Control
always@(posedge CLK or negedge RESET_N)
	if (!RESET_N)
	begin
		rWR1_ADDR		  <=	WR1_ADDR;
		rWR2_ADDR		  <=	WR2_ADDR;
		rRD1_ADDR		  <=	RD1_ADDR;
		rRD2_ADDR		  <=	RD2_ADDR;
		rWR1_MAX_ADDR	<=	WR1_MAX_ADDR;
		rWR2_MAX_ADDR	<=	WR2_MAX_ADDR;
		rRD1_MAX_ADDR	<=	RD1_MAX_ADDR;
		rRD2_MAX_ADDR	<=	RD2_MAX_ADDR;
	end
	else
	begin
		//	Write Side 1
   if (WR1_LOAD) begin
      rWR1_ADDR	<= WR1_ADDR;
		rWR1_MAX_ADDR	<= WR1_MAX_ADDR;
	end else if (WR1_DONE) begin
		if(rWR1_ADDR<rWR1_MAX_ADDR-WR1_LENGTH)
			rWR1_ADDR	<= rWR1_ADDR+WR1_LENGTH;
		else
			rWR1_ADDR	<= WR1_ADDR;
	end		
		//	Write Side 2
   if (WR2_LOAD) begin
      rWR2_ADDR	<= WR2_ADDR;
		rWR2_MAX_ADDR	<= WR2_MAX_ADDR;
   end else if (WR2_DONE) begin
	 	if(rWR2_ADDR<rWR2_MAX_ADDR-WR2_LENGTH)
			rWR2_ADDR	<=	rWR2_ADDR+WR2_LENGTH;
		else
			rWR2_ADDR	<=	WR2_ADDR;
	end	
		//	Read Side 1
   if (RD1_LOAD) begin
      rRD1_ADDR	<= RD1_ADDR;
		rRD1_MAX_ADDR	<= RD1_MAX_ADDR;
	end else if (RD1_DONE) begin
		if(rRD1_ADDR<rRD1_MAX_ADDR-RD1_LENGTH)
			rRD1_ADDR	<=	rRD1_ADDR+RD1_LENGTH;
		else
			rRD1_ADDR	<=	RD1_ADDR;
	end		
		//	Read Side 2
   if (RD2_LOAD) begin
      rRD2_ADDR	<= RD2_ADDR;
		rRD2_MAX_ADDR	<= RD2_MAX_ADDR;
   end else if (RD2_DONE) begin
		if(rRD2_ADDR<rRD2_MAX_ADDR-RD2_LENGTH)
			rRD2_ADDR	<=	rRD2_ADDR+RD2_LENGTH;
		else
			rRD2_ADDR	<=	RD2_ADDR;
	end	
end

//	Auto Read/Write Control
always@(posedge CLK or negedge RESET_N)
	if (!RESET_N)
	begin
		mWR		<=	0;
		mRD		<=	0;
		mADDR    <=	0;
		mLENGTH	<=	0;		
		WR_MASK  <=	0; //added by Peli 2010-07-21
		RD_MASK  <=	0;
	end
	else
	begin
		if ( !mWR && !mRD && 
			   (ST==0) && (WR_MASK==0) &&	(RD_MASK==0) &&
			   !WR1_LOAD &&	!RD1_LOAD && !WR2_LOAD &&	!RD2_LOAD )
		begin
			//	Write Side 1
			if ( (write_side_fifo_rusedw1 >= WR1_LENGTH) && (WR1_LENGTH!=0) )
			begin
				mADDR	   <=	rWR1_ADDR;
				mLENGTH	<=	WR1_LENGTH;
				WR_MASK	<=	2'b01;
				RD_MASK	<=	2'b00;
				mWR		<=	1;
				mRD		<=	0;
			end
			//	Write Side 2
			else if ( (write_side_fifo_rusedw2 >= WR2_LENGTH) && (WR2_LENGTH!=0) )
			begin
				mADDR	   <=	rWR2_ADDR;
				mLENGTH	<=	WR2_LENGTH;
				WR_MASK	<=	2'b10;
				RD_MASK	<=	2'b00;
				mWR		<=	1;
				mRD		<=	0;
			end
			//	Read Side 1
			else if ( (read_side_fifo_wusedw1 < RD1_LENGTH) )
			begin
				mADDR	   <=	rRD1_ADDR;
				mLENGTH	<=	RD1_LENGTH;
				WR_MASK	<=	2'b00;
				RD_MASK	<=	2'b01;
				mWR		<=	0;
				mRD		<=	1;				
			end
			//	Read Side 2
			else if ( (read_side_fifo_wusedw2 < RD2_LENGTH) )
			begin
				mADDR  	<=	rRD2_ADDR;
				mLENGTH	<=	RD2_LENGTH;
				WR_MASK	<=	2'b00;
				RD_MASK	<=	2'b10;
				mWR		<=	0;
				mRD		<=	1;
			end		
		end
		
		if (mWR_DONE)
		begin
			WR_MASK	<=	0;
			mWR		<=	0;
		end
		
		if (mRD_DONE)
		begin
			RD_MASK	<=	0;
			mRD		<=	0;
		end
	end

endmodule
