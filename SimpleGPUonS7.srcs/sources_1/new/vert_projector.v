`timescale 1ns / 1ps

module vert_projector(
        input i_clk,
        input in_start,
        input [255:0] mvp_in,
        input [63:0] vertex_in,
        output out_done,
        output [47:0] out_vector
    );
    
       parameter Q = 8;
       parameter N = 16;
    
       wire [63:0] result;
       reg in_start_1;
       
       wire division_done;
       reg inProgress = 0;
       reg [8:0] counter = 0;
       reg divide_start = 0;
       wire [15:0] xResult;
       wire [15:0] yResult;
       wire[15:0] zResult;
       
       reg out_done_reg = 0;
       reg [47:0] out_vector_reg = 0;
        
        assign out_done = out_done_reg;
        assign out_vector = out_vector_reg;
       
       localparam WAIT = 17;
       
            
     matrix4x4x1#(
           .Q(Q),
           .N(N)
           ) vertexMultipler 
               (    
                .mvp_in( mvp_in),
               .vertex_in(vertex_in),
               .result( result)
               );
               
               
       // we should instantiate 3 dividers - 
       // one for each vector component.
       // we somehow need to wait to start dividing until the 
       // result is valid...
                            
     qdiv#(
           .Q(Q),
           .N(N))
               xDivider(
               .i_dividend(result[63:48]),
               .i_divisor(result[15:0]),
               .i_start(divide_start),
               .i_clk(i_clk),
               .o_quotient_out(xResult),
               .o_complete(division_done)
               );
               
        qdiv#(
            .Q(Q),
            .N(N))
                yDivider(
                .i_dividend(result[47:32]),
                .i_divisor(result[15:0]),
                .i_start(divide_start),
                .i_clk(i_clk),
                .o_quotient_out(yResult),
                .o_complete(division_done)
                );
                
    qdiv#(
           .Q(Q),
           .N(N))
               zDivider(
               .i_dividend(result[31:16]),
               .i_divisor(result[15:0]),
               .i_start(divide_start),
               .i_clk(i_clk),
               .o_quotient_out(zResult),
               .o_complete(division_done)
               );
               
             
//we need N clocks before the division result is ready.
               always @(posedge i_clk) begin
                    in_start_1 <= in_start;
                    
                   //only do anything if we detect a start pulse.
                   if(in_start && ~in_start_1 || (inProgress == 1)) begin
                       //we saw the pulse so we're now doing our work:
                       inProgress <= 1;
                       //lets wait x count before starting division.
                       counter <= counter + 1;
                        if (counter > WAIT) begin
                       // start dividing - then wait another 17 clocks to be safe.
                       // or wait until the complete signal is raised.
                            divide_start <= 1;
                                if(division_done == 1 && counter > WAIT * 2) begin
                                    // we're done dividing
                                    out_done_reg <= 1;
                                    counter <= 0;
                                    divide_start <= 0;
                                    inProgress <= 0;
                                    out_vector_reg <= {xResult,yResult,zResult}; 
                            end // if
                        end // if
                    end //start if
               end // always
               
endmodule
