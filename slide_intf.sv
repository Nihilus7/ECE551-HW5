module slide_intf(clk, rst_n, MISO, a2d_SS_n, SCLK, MOSI, POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME);
// A2D_intf in/out
input clk, rst_n;
input MISO;
output a2d_SS_n, SCLK, MOSI;
// A2D_intf - RRsequencer wires
wire [11:0] res;
reg [2:0] chnnl;
reg strt_cnv;
wire cnv_cmplt;
// slide_intf outputs
output reg [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME;

// Instantiate A2D_intf
A2D_intf iA2D(.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .cnv_cmplt(cnv_cmplt), .chnnl(chnnl), .res(res), .a2d_SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

// strt_cnv flop
always_ff @(posedge clk)
	if (cnv_cmplt)
		strt_cnv <= 1'b1;
	else
		strt_cnv <= 1'b0;

// chnnl flop
always_ff @(posedge clk)
	if (cnv_cmplt)
		if (chnnl[2])
			chnnl <= 3'h7;
		else
			chnnl <= chnnl + 1'b1;

// POT_LP flop
always_ff @(posedge clk)
	if (cnv_cmplt && chnnl == 3'h0)
		POT_LP <= res;

// POT_B1 flop
always_ff @(posedge clk)
	if (cnv_cmplt && chnnl == 3'h1)
		POT_B1 <= res;

// POT_B2 flop
always_ff @(posedge clk)
	if (cnv_cmplt && chnnl == 3'h2)
		POT_B2 <= res;

// POT_B3 flop
always_ff @(posedge clk)
	if (cnv_cmplt && chnnl == 3'h3)
		POT_B3 <= res;

// POT_HP flop
always_ff @(posedge clk)
	if (cnv_cmplt && chnnl == 3'h4)
		POT_HP <= res;

// VOLUME flop
always_ff @(posedge clk)
	if (cnv_cmplt && chnnl == 3'h7)
		VOLUME <= res;
endmodule
