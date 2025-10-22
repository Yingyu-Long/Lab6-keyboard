module keyboard (input logic MAX10_CLK1_50,
						input logic KEY0,
						inout wire [15:0] ARDUINO_IO,
						output logic[9:0] LEDR)；
						
						logic [3:0] row_scan, keycode,row,col;
						logic clk, reset;
						logic valid_db,debounceOK,key_validn;
						
						assign reset = ~KEY0;
						assign clk = MAX10_CLK1_50;
						
						 kb_db #(.DELAY(16)) kb_debounce (.clk(clk),
																	  .rst(reset),
																	  .row_wires(ARDUINO_IO[7:4]),
																	  .col_wires(ARDUINO_IO[3:0]),
																	  .row_scan(row_scan),
																	  .row(row),
																	  .col(col),
																	  .valid(valid_db),
																	  .debounceOK(debounceOK));
																	  
																	  
																	  
						
						  keyboard_fsm fsm (.clk(clk),
												  .reset(reset),
												  .row(row),
												  .col(col),
												  .keycode(keycode),
												  .row_scan(row_scan),
												  .key_valid(key_validn));
						
						

endmodule
						
module kb_db #( DELAY=16 ) (
			input logic clk,
			input logic rst,
			inout wire [3:0] row_wires, // could be ‘output logic’
			inout wire [3:0] col_wires, // could be ‘input logic’
			input logic [3:0] row_scan,
			output logic [3:0] row,
			output logic [3:0] col,
			output logic valid,
			output logic debounceOK);
			
			
			logic [3:0] col_F1, col_F2;
			logic [3:0] row_F1, row_F2;
			logic pressed, row_change, col_change;
			assign row_wires = row_scan;
			assign pressed = ~&( col_F2 );
			assign col_change = pressed ^ pressed_sync;
			assign row_change = |(row_scan ^ row_F1);
			logic [3:0] row_sync, col_sync;
			logic pressed_sync;
// synchronizer
			always_ff @( posedge clk ) begin
				row_F1 <= row_scan; col_F1 <= col_wires;
				row_F2 <= row_F1; col_F2 <= col_F1;
				row_sync <= row_F2; col_sync <= col_F2;
				//
				pressed_sync <= pressed;
			end
			
			
// final retiming flip-flops
// ensure row/col/valid appear together at the same time
			always_ff @( posedge clk ) begin
				valid <= debounceOK & pressed_sync;
				if( debounceOK & pressed_sync ) begin
					row <= row_sync;
					col <= col_sync;
					end else begin
					row <= 0;
					col <= 0;
			end
	end
	
// debounce counter
		logic [DELAY:0] counter;
		initial counter = 0;
		always_ff @( posedge clk ) begin
		if( rst | row_change | col_change ) begin
			counter <= 0;
		end else if( !debounceOK ) begin
			counter <= counter+1;
			end
		end
		assign debounceOK = counter[DELAY];
endmodule


module keyboard_fsm(input logic clk,
						  input logic reset,
						  input logic [3:0] row, col,
						  output logic [3:0] keycode,
						  output logic [3:0] row_scan
						  output logic key_valid);
						  
						  logic [1:0] present_state, next_state;
						  logic key_hold;
						  
						  always_ff @(posedge clk) begin
								if(reset) begin
									present_state <= 2'b00;
									key_hold <= 0;
									keycode <= 4'h0;
									key_valid <= 0;
								end
								else begin
									present_state <= next_state;
									key_valid <=0;
								end
							end
							
							always_comb begin
							keycode = 4'h0;
							key_valid = 1'b0;
								case({row_scan,col})
									8'b1110_1110:begin
										keycode = 4'h1;
										key_validn =1;
									end
									
									8'b1110_1101:begin
										keycode = 4'h2;
										key_validn =1;
									end	
							
									8'b1110_1011:begin
										keycode = 4'h3;
										key_validn =1;
									end	
									
									8'b1110_0111:begin
										keycode = 4'h2;
										key_validn =1;
									end
									
									8'b1101_1110: begin
										  keycode = 4'h4;
										  key_valid = 1'b1;
									 end
									 
									 8'b1101_1101: begin
										  keycode = 4'h5;
										  key_valid = 1'b1;
									 end
									 
									 8'b1101_1011: begin
										  keycode = 4'h6;
										  key_valid = 1'b1;
									 end
									 
									 8'b1101_0111: begin
										  keycode = 4'hB;
										  key_valid = 1'b1;
									 end
									 
									 // Row 3
									 8'b1011_1110: begin
										  keycode = 4'h7;
										  key_valid = 1'b1;
									 end
									 
									 8'b1011_1101: begin
										  keycode = 4'h8;
										  key_valid = 1'b1;
									 end
									 
									 8'b1011_1011: begin
										  keycode = 4'h9;
										  key_valid = 1'b1;
									 end
									 
									 8'b1011_0111: begin
										  keycode = 4'hC;
										  key_valid = 1'b1;
									 end
									 
									 // Row 4
									 8'b0111_1110: begin
										  keycode = 4'hE; // *
										  key_valid = 1'b1;
									 end
									 
									 8'b0111_1101: begin
										  keycode = 4'h0;
										  key_valid = 1'b1;
									 end
									 
									 8'b0111_1011: begin
										  keycode = 4'hF; // #
										  key_valid = 1'b1;
									 end
									 
									 8'b0111_0111: begin
										  keycode = 4'hD;
										  key_valid = 1'b1;
									 end
									 
									 default: begin
										  key_valid = 1'b0;
									 end
								endcase;
							end	
							
							
							always_comb begin
							nesxt_state = present_state;
								case(present_state)
									2'b00: begin
										next_state = 2'b01;
										row_scan = 4'b1110;
									end
									
									2'b01: begin
										next_state = 2'b10;
										row_scan = 4'b1101;
									end
									
									2'b10: begin
										next_state = 2'b11;
										row_scan = 4'b1011;
									end
									
									2'b11 begin 
										next_state = 2'b00;
										row_scan = 4'b0111;
									end
								endcase
							end
endmodule
							

									
								
									
								
