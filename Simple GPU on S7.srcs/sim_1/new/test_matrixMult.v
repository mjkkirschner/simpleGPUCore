`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2018 06:51:22 PM
// Design Name: 
// Module Name: test_matrixMult
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_matrixMult;
       
       //inputs
        reg [0:255] mvp_in;
        reg [0:63] vertex_in;
        
        //outputs
        wire [0:63] result;
        
        matrix4x4x1  
        #(
        .Q(4),
        .N(16)) 
        
        uut(.mvp_in( mvp_in),
            .vertex_in(vertex_in),
            .result( result)
            );
        
        initial begin 
       		$monitor ("%b,%b,%b", mvp_in, vertex_in, result);		//	Monitor the stuff we care about
       		//ident matrix
            mvp_in = {{16'b0000000000010000},{16'b0000000000000000},{16'b0000000000000000},{16'b0000000000000000},
                        {16'b0000000000000000},{16'b0000000000010000},{16'b0000000000000000},{16'b0000000000000000},
                        {16'b0000000000000000},{16'b0000000000000000},{16'b0000000000010000},{16'b0000000000000000},
                        {16'b0000000000000000},{16'b0000000000000000},{16'b0000000000000000},{16'b0000000000010000}
                        };
                        
            //[5,5,5,5]
            vertex_in = {{16'b0000000001010000},{16'b0000000001010000},{16'b0000000001010000},{16'b0000000001010000}};
                        
            // Wait 100 ns for global reset to finish
            #100;
            $finish;
            end
            
        
endmodule
