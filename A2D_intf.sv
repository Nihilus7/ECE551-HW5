// A2D Interface

module A2D_intf (clk, rst_n, strt_cnv, chnnl, cnv_cmplt, res, a2d_ss_n, SCLK, MOSI, MISO);

	input clk, rst_n, strt_cnv, MISO;
	input [2:0] chnnl;
	
	output a2d_ss_n, SCLK, MOSI;
        output reg cnv_cmplt;
	output [11:0] res;
	
	wire [15:0] cmd;
	wire done;

	typedef enum reg[1:0] {IDLE, INIT1, WAIT, INIT2} state_t;
	state_t state, nstate; 			// declare enum types   

	///SM-outputs (should be defined as type logic)
	logic set_cnv_cmplt, wrt;

	//Instantiate DUT//
	SPI_mstr mstr(.clk(clk),.rst_n(rst_n),.SS_n(a2d_SS_n),.SCLK(SCLK),.MISO(MISO),
		.MOSI(MOSI),.wrt(wrt), .done(done), .rd_data(res),.cmd(cmd));
			
	// constant ASSIGN statements //
	assign cmd = {2'b00, chnnl,11'h000};
	
	//Implement state register
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= nstate;

       always_ff @(posedge clk, negedge rst_n)
          if (!rst_n)
            cnv_cmplt <= 1'b0;
          else if (set_cnv_cmplt)
             cnv_cmplt <= 1'b1;
          else if (strt_cnv)
             cnv_cmplt <= 1'b0;
	

	// continuous assign for
	
	//*****SM******//
	always_comb begin 
		// deafult SM values
		set_cnv_cmplt = 0;
		wrt = 0;
		nstate = IDLE;
		
				case(state) 
				
					IDLE:   begin
					//strt_conv needs to be held for atleast one clk cyc
					  //??? 
					  if(strt_cnv) begin
					    nstate = INIT1;
					    wrt = 1;
					  end else
	                   			nstate = IDLE;
					end
					
					INIT1:  begin
					  if(done)
					   nstate = WAIT;
					  else 
					   nstate = INIT1;
					end
					
					WAIT:   begin
					  nstate = INIT2;
					  wrt = 1;
					end
					
					INIT2:  begin
					  if(done) begin
					    set_cnv_cmplt = 1;
					    nstate = IDLE;
					  end else
					  nstate = INIT2;
					end
				
				endcase
	
	
	end
endmodule
