
//--------------------------------------------------------------------------------------------------------
// Module  : tx_specified_len
// Type    : synthesizable
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: receive 4 bytes from AXI-stream slave,
//           then regard the 4 bytes as a length, send length of bytes on AXI-stream master
//           this module will called by fpga_top_ft600_tx_mass.v or fpga_top_ft232h_tx_mass.v
//--------------------------------------------------------------------------------------------------------

module tx_specified_len (
    input  wire        rstn,
    input  wire        clk,
	 input  wire        ahmed_clk,
    input  wire        ahmed_data,
    // AXI-stream slave
    output wire        i_tready,
    input  wire        i_tvalid,
    input  wire [ 7:0] i_tdata,
    // AXI-stream master
    input  wire        o_tready,
    output wire        o_tvalid,
    output wire [31:0] o_tdata,
    output wire [ 3:0] o_tkeep,
    output wire        o_tlast
);


localparam [2:0] RX_BYTE0 = 3'd0,
                 RX_BYTE1 = 3'd1,
                 RX_BYTE2 = 3'd2,
                 RX_BYTE3 = 3'd3,
                 TX_DATA  = 3'd4;

reg [ 2:0]       state = RX_BYTE0;

reg [31:0]       length = 0;


always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        state  <= RX_BYTE0;
        length <= 0;
    end else begin
        case (state)
            RX_BYTE0 : if (i_tvalid) begin
                length[ 7: 0] <= i_tdata;
                state <= RX_BYTE1;
            end
            
            RX_BYTE1 : if (i_tvalid) begin
                length[15: 8] <= i_tdata;
                state <= RX_BYTE2;
            end
            
            RX_BYTE2 : if (i_tvalid) begin
                length[23:16] <= i_tdata;
                state <= RX_BYTE3;
            end
            
            RX_BYTE3 : if (i_tvalid) begin
                length[31:24] <= i_tdata;
                state <= TX_DATA;
            end
            
            default :  // TX_DATA :
                if (o_tready /*&& rdusedw_sig>10*/) begin
                    if (length >= 4) begin
                        length <= length - 4;
								//rdreq_sig = 1'b1;
								//o_tvalid = 1'b1;
								//o_tdata = q_sig;
                    end else begin
                        length <= 0;
                        state <= RX_BYTE0;
                    end
                end
					 else begin
						  //o_tvalid = 1'b0;
					 end
        endcase
    end


assign i_tready = (state != TX_DATA);

assign o_tvalid = (state == TX_DATA); // remove this

assign o_tdata  = {length[7:0],
                   length[7:0],
                   7'd0,ahmed_clk,
                   7'd0,ahmed_data }; // remove this

assign o_tkeep  = (length>=4) ? 4'b1111 :
                  (length==3) ? 4'b0111 :
                  (length==2) ? 4'b0011 :
                  (length==1) ? 4'b0001 :
                 /*length==0*/  4'b0000;

assign o_tlast  = (length>=4) ? 1'b0 : 1'b1;

wire rdreq_sig;
wire wrreq_sig;
wire [5:0] rdusedw_sig;
wire [31:0] q_sig;

ahmed_fifo	ahmed_fifo_inst (
	.data ( ahmed_data ),
	.rdclk ( clk ),
	.rdreq ( rdreq_sig ),
	.wrclk ( ahmed_clk ),
	.wrreq ( wrreq_sig ),
	.q ( q_sig ),
	//.rdempty ( rdempty_sig ),
	//.wrfull ( wrfull_sig ),
	.rdusedw ( rdusedw_sig )
	);


endmodule
