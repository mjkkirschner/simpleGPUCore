`timescale 1ns / 1ps

module test_vert_projector(

    );
     //inputs
           reg clk, inStart;
           reg [255:0] mvp_in;
           reg [63:0] vertex_in;
           
           //outputs
           wire [47:0] projected_vector;
           wire out_done;
           
           vert_projector #(.Q(4),.N(16)) 
           uut(.i_clk(clk),
                .in_start(inStart),
                .mvp_in( mvp_in),
               .vertex_in(vertex_in),
               .out_vector( projected_vector),
               .out_done(out_done)
               );
           
           
                  initial 
                   begin 
                      $monitor ("matrix: %b \n, vertex: %b \n ,projectedVert: %b \n ,start: %b \n, done: %b \n", mvp_in, vertex_in, projected_vector, inStart , out_done);        //    Monitor the stuff we care about
                     clk = 0; 
                     inStart = 0;
                     mvp_in = {{16'b0000000000010000},{16'b0000000000000000},{16'b0000000000000000},{16'b0000000000000000},
                                                {16'b0000000000000000},{16'b0000000000010000},{16'b0000000000000000},{16'b0000000000000000},
                                                {16'b0000000000000000},{16'b0000000000000000},{16'b0000000000010000},{16'b0000000000000000},
                                                {16'b0000000000000000},{16'b0000000000000000},{16'b0000000000000000},{16'b0000000000010000}
                                                };
                     vertex_in = {{16'b0000000001010000},{16'b0000000001010000},{16'b0000000001010000},{16'b0000000000010000}};
                     
                     #100 inStart <= 1;
                     
                     
                   end 
                     
                   always 
                      #5  clk =  ! clk; 
           
 
endmodule
