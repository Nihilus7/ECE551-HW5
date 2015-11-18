module codec_intf(clk, rst_n, LRCLK, SCLK, MCLK, RSTn, SDout, SDin, lft_in, rht_in, valid, lft_out, rht_out);
input clk, rst_n;

// in/out of dig core:
input [15:0] lft_out, rht_out;
output [15:0] lft_in, rht_in;
output reg valid;

// in/out of CODEC:
input SDout;
output SDin;
output reg RSTn;
output LRCLK, SCLK, MCLK;

reg [9:0] cnt;	// 10bit counter with various bits aligned to different clock speeds

wire LRCLK_rising, LRCLK_falling, SCLK_rising, SCLK_falling;	// Clock events used to trigger shifts and loads
wire set_vld;	// Wire triggering valid output
reg [15:0] rht_buffer, lft_buffer, shift_reg_SDin, shift_reg_lft_in, shift_reg_rht_in;	// Internal buffers and shift regs

// RSTn logic
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		RSTn <= 1'b0;
	else if (LRCLK_rising)
		RSTn <= 1'b1;

// Counter logic
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		cnt <= 10'h200;
	else
		cnt <= cnt + 1'b1;

// Left Buffer
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		lft_buffer <= 16'h0000;
	else if (set_vld)
		lft_buffer <= lft_out;

// Right Buffer
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		rht_buffer <= 16'h0000;
	else if (set_vld)
		rht_buffer <= rht_out;

// Shift Reg producing SDin
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		shift_reg_SDin <= 16'h0000;
	else if (LRCLK_rising)
		shift_reg_SDin <= lft_buffer;
	else if (LRCLK_falling)
		shift_reg_SDin <= rht_buffer;
	else if (SCLK_falling)
		shift_reg_SDin <= {shift_reg_SDin[14:0], 1'b0};

// Shift Regs sampling SDout
always_ff @(posedge clk)
	if (LRCLK && SCLK_rising)
		shift_reg_lft_in <= {shift_reg_lft_in[14:0], SDout};

// Shift Regs sampling SDout
always_ff @(posedge clk)
	if (!LRCLK && SCLK_rising)
		shift_reg_rht_in <= {shift_reg_rht_in[14:0], SDout};

assign SDin = shift_reg_SDin[15];
assign lft_in = shift_reg_lft_in;	// Could have just made lft_in/rht_in output regs, but thisis shown to make
assign rht_in = shift_reg_rht_in;	// reader aware the outputs are based on regs that may not always be valid

// Set Valid
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		valid <= 1'b0;
	else if (set_vld && SCLK_rising)
		valid <= 1'b1;
	else if (SCLK_falling)
		valid <= 1'b0;

assign LRCLK = cnt[9];	// 1/1024 clk
assign SCLK = cnt[4];	// 1/32 clk
assign MCLK = cnt[1];	// 1/4 clk

assign set_vld = (cnt == 10'h1ef) ? 1'b1 : 1'b0;			// set_vld triggers valid at the last rising edge of SCLK before LRCLK goes high
assign LRCLK_rising = (~cnt[9] && &cnt[8:0]) ? 1'b1 : 1'b0;	// If all LSBs of cnt are all 1, and LRCLK is low, next cnt will cause SCLK to rise
assign LRCLK_falling = (&cnt) ? 1'b1 : 1'b0;				// If cnt is all 1s, next cnt will cause LRCLK to fall
assign SCLK_rising = (~cnt[4] && &cnt[3:0]) ? 1'b1 : 1'b0;	// If 4 LSBs of cnt are all 1, and SCLK is low, next cnt will cause SCLK to rise
assign SCLK_falling = (&cnt[4:0]) ? 1'b1 : 1'b0;			// If 5 LSBs of cnt are all 1, next cnt will cause SCLK to fall

endmodule
