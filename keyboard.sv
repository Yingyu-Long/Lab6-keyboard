module keyboard(
    input  logic        clk,
    input  logic        KEY0,
    inout  wire [15:0]  ARDUINO_IO,
    output logic [9:0]  LEDR,
    output logic [6:0]  HEX5, HEX4, HEX3, HEX2, HEX1, HEX0
);

    // Clock and reset
    logic reset;
    assign reset = ~KEY0;

    // FSM state for row scanning
    typedef enum logic [1:0] {ROW0=2'b00, ROW1=2'b01, ROW2=2'b10, ROW3=2'b11} state_t;
    state_t present_state, next_state;

    // Row scan output
    logic [3:0] row_scan;

    logic [3:0] row_db, col_db, keycode;
    logic valid, debounceOK;

    logic [23:0] key_store;

    kb_db #(.DELAY(16)) kb_debounce (
        .clk(clk),
        .rst(reset),
        .row_wires(ARDUINO_IO[7:4]),
        .col_wires(ARDUINO_IO[3:0]),
        .row_scan(row_scan),
        .row(row_db),
        .col(col_db),
        .valid(valid),
        .debounceOK(debounceOK)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            present_state <= ROW0;
        else
            present_state <= next_state;
    end

    always_comb begin
        next_state = present_state;
        case(present_state)
            ROW0: if (!valid) next_state = ROW1;
            ROW1: if (!valid) next_state = ROW2;
            ROW2: if (!valid) next_state = ROW3;
            ROW3: if (!valid) next_state = ROW0;
        endcase

        case(present_state)
            ROW0: row_scan = 4'b1110;
            ROW1: row_scan = 4'b1101;
            ROW2: row_scan = 4'b1011;
            ROW3: row_scan = 4'b0111;
            default: row_scan = 4'b1111;
        endcase
    end

    always_comb begin
        keycode = 4'h0;
        if (valid) begin
            case({row_db, col_db})
                8'b1110_1110: keycode = 4'h1;
                8'b1110_1101: keycode = 4'h2;
                8'b1110_1011: keycode = 4'h3;
                8'b1110_0111: keycode = 4'hA;
                8'b1101_1110: keycode = 4'h4;
                8'b1101_1101: keycode = 4'h5;
                8'b1101_1011: keycode = 4'h6;
                8'b1101_0111: keycode = 4'hB;
                8'b1011_1110: keycode = 4'h7;
                8'b1011_1101: keycode = 4'h8;
                8'b1011_1011: keycode = 4'h9;
                8'b1011_0111: keycode = 4'hC;
                8'b0111_1110: keycode = 4'hE; // *
                8'b0111_1101: keycode = 4'h0;
                8'b0111_1011: keycode = 4'hF; // #
                8'b0111_0111: keycode = 4'hD;
                default: keycode = 4'h0;
            endcase
        end
    end

    // Shift keycode into 24-bit register
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            key_store <= 24'b0;
        else if (valid)
            key_store <= {key_store[19:0], keycode};
    end

    // Assign to HEX displays (raw 4-bit values)
    assign HEX5 = key_store[23:20];
    assign HEX4 = key_store[19:16];
    assign HEX3 = key_store[15:12];
    assign HEX2 = key_store[11:8];
    assign HEX1 = key_store[7:4];
    assign HEX0 = key_store[3:0];

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





