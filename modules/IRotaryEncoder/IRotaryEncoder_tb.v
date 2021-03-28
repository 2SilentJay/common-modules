`timescale 100 ns / 10 ns
`include "../assert.v"

module IRotaryEncoder_tb();

parameter CLOCK_PERIOD = 1;
parameter DELAY_CLOCK_CYCLES = 4/*IRotaryEncoder*/ + 1/*update ra_cnt*/;
parameter COUNTER_WIDTH = 2;
parameter COUNTER_RANGE = 2 ** COUNTER_WIDTH;
parameter COUNTER_MAX = COUNTER_RANGE - 1;

reg r_clk = 0;
reg r_phase_a = 0;
reg r_phase_b = 0;
reg [COUNTER_WIDTH - 1 : 0] ra_cnt = 0;
reg r_watch_dog = 0;
wire w_cnt;
wire w_cnt_cw;

// setup clock
always begin
	#CLOCK_PERIOD r_clk = ~r_clk;
end

// setup watchdog
always @(w_cnt or w_cnt_cw) begin
	if(r_watch_dog)
		`assert_fail;
end

always@(posedge r_clk) begin
	if(w_cnt)
		ra_cnt <= ra_cnt + (w_cnt_cw ? 1 : -1);
end

IRotaryEncoder uut(r_clk, r_phase_a, r_phase_b, w_cnt, w_cnt_cw);

// common tasks
task set_phase;
input [1:0] ia_phase;
begin
	@(negedge r_clk);
	r_phase_a <= ia_phase[0];
	r_phase_b <= ia_phase[1];
end
endtask

task wait_response;
repeat (DELAY_CLOCK_CYCLES) begin
		@(posedge r_clk);
	end
endtask

initial begin

	// Init state.
	set_phase(2'b00);
	wait_response();

	// Rotate clockwise in the full cycle.
	repeat (COUNTER_MAX) begin
		set_phase(2'b01);
		set_phase(2'b11);
		set_phase(2'b10);
		set_phase(2'b00);

		wait_response();
	end
	`assert_eq(ra_cnt, COUNTER_MAX);

	// Rotate counterclockwise in the full cycle.
	repeat (COUNTER_MAX) begin
		set_phase(2'b10);
		set_phase(2'b11);
		set_phase(2'b01);
		set_phase(2'b00);

		wait_response();
	end
	`assert_eq(ra_cnt, 0);

	// Rotate clockwise in the short cycle.
	repeat (COUNTER_MAX) begin
		set_phase(2'b01);
		set_phase(2'b10);
		set_phase(2'b00);

		wait_response();
	end
	`assert_eq(ra_cnt, COUNTER_MAX);

	// Rotate counterclockwise in the short cycle.
	repeat (COUNTER_MAX) begin
		set_phase(2'b10);
		set_phase(2'b01);
		set_phase(2'b00);

		wait_response();
	end
	`assert_eq(ra_cnt, 0);


	// Inconsistent input.
	// No response must be given.
	r_watch_dog = 1;

	// Separate pulses.
	repeat (COUNTER_MAX) begin
		set_phase(2'b01);
		set_phase(2'b00);
		set_phase(2'b10);
		set_phase(2'b00);

		wait_response();
	end

	// Glitchy phases.
	repeat (COUNTER_MAX) begin
		set_phase(2'b00);
		set_phase(2'b11);
		set_phase(2'b00);

		wait_response();
	end

	repeat (COUNTER_MAX) begin
		set_phase(2'b00);
		set_phase(2'b10);
		set_phase(2'b11);
		set_phase(2'b10);
		set_phase(2'b00);

		wait_response();
	end

	repeat (COUNTER_MAX) begin
		set_phase(2'b00);
		set_phase(2'b01);
		set_phase(2'b11);
		set_phase(2'b01);
		set_phase(2'b00);

		wait_response();
	end

	repeat (COUNTER_MAX) begin
		set_phase(2'b00);
		set_phase(2'b10);
		set_phase(2'b11);
		set_phase(2'b00);

		wait_response();
	end

	repeat (COUNTER_MAX) begin
		set_phase(2'b00);
		set_phase(2'b01);
		set_phase(2'b11);
		set_phase(2'b00);

		wait_response();
	end

	#DELAY_CLOCK_CYCLES;
	`assert_pass;
end

initial begin
	$dumpfile("IRotaryEncoder_tb.vcd");
	$dumpvars(0, IRotaryEncoder_tb);
end

endmodule
