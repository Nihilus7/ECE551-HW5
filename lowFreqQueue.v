module lowFreqQueue(clk, rst_n, new_smpl, wrt_smpl, smpl_out, sequencing);
input clk, rst_n;
input [15:0] new_smpl;
input wrt_smpl;

output [15:0] smpl_out;
output sequencing;

logic read, write, set_read_ptr;

typedef enum reg {IDLE, READ} state_t;
state_t state, nxt_state;

reg [9:0] read_ptr, new_ptr, old_ptr;
reg queue_full;

wire [9:0] end_ptr;
assign end_ptr = old_ptr + 10'h3fd;

assign sequencing = read;

// Instantiate dualPort1024x16
dualPort1024x16 idualPort1024x16(.clk(clk), .we(write), .waddr(new_ptr), .raddr(read_ptr), .wdata(new_smpl), .rdata(smpl_out));

// State Register
always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		new_ptr <= 10'h000;
	else if (write)
		new_ptr <= new_ptr + 1'b1;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		old_ptr <= 10'h000;
	else if (write && queue_full)
		old_ptr <= old_ptr + 1'b1;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		read_ptr <= 10'h000;
	else if (set_read_ptr)
		read_ptr <= old_ptr; // This may have to be old_ptr + 1 depending on how write occurs
	else // if (read)
		read_ptr <= read_ptr + 1'b1;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		queue_full <= 1'b0;
	else if (new_ptr == 10'h3fd) // Once new_ptr hits 1021, the queue is full
		queue_full <= 1'b1;

always_comb begin
	nxt_state = IDLE;
	write = 0;
	read = 0;
	set_read_ptr = 0;
	
	case(state)
		READ : begin
			read = 1;
			if (read_ptr != end_ptr)
				nxt_state = READ;
			// else if (read_ptr == end_ptr) nxt_state = IDLE
		end
		default : begin // IDLE
			if (wrt_smpl) begin
				write = 1;
				if (queue_full) begin
					set_read_ptr = 1;
					nxt_state = READ;
				end
			end // else nxt_state = IDLE
		end
	endcase
end
endmodule
