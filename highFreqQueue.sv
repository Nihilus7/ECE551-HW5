module highFreqQueue(clk, rst_n, new_smpl, wrt_smpl, smpl_out, sequencing);
input clk, rst_n;
input [15:0] new_smpl;
input wrt_smpl;

output [15:0] smpl_out;
output sequencing;

logic read, write, set_read_ptr;

typedef enum reg {IDLE, READ} state_t;
state_t state, nxt_state;

reg [10:0] read_ptr, new_ptr, old_ptr;
reg queue_full;

wire [10:0] end_ptr;
// If old_ptr + 1024 > 1535, subtracts 513 from old_ptr, otherwise adds 1024 to old_ptr
assign end_ptr = ((old_ptr + 10'h3fd) > 11'h5ff) ? (old_ptr - 10'h201) : (old_ptr + 10'h3fd);

assign sequencing = read;

// Instantiate dualPort1536x16
dualPort1536x16 idualPort1536x16(.clk(clk), .we(write), .waddr(new_ptr), .raddr(read_ptr), .wdata(new_smpl), .rdata(smpl_out));

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
		if (new_ptr == 11'h5ff)
			new_ptr <= 11'h000;
		else
			new_ptr <= new_ptr + 1'b1;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		old_ptr <= 11'h000;
	else if (write && queue_full)
		if (old_ptr == 11'h5ff)
			old_ptr <= 11'h000;
		else
			old_ptr <= old_ptr + 1'b1;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		read_ptr <= 10'h000;
	else if (set_read_ptr)
		read_ptr <= old_ptr; // This may have to be old_ptr + 1 depending on how write occurs
	else if (read_ptr == 11'h5ff)
		read_ptr <= 11'h000;
	else
		read_ptr <= read_ptr + 1'b1;

always_ff @(posedge clk, negedge rst_n)
	if (!rst_n)
		queue_full <= 1'b0;
	else if (new_ptr == 10'h5fb) // Once new_ptr hits 1531, the queue is full
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
