`timescale 1ns / 1ps
module ViewToScreenConverter(
        
        //width and height are 16 bit integers (really 11)
        input [11:0] width_in,
        input [11:0] height_in,
        //vector format [16bit,16,16] - each component is [1signbit,11databits,4Qbits]
        input [47:0] vector_in,
        
        output [11:0] xpix_out,
        output [11:0] ypix_out,
        output on_screen_out

    );
    
     parameter Q = 8;
     parameter N = 16;
    
    wire [15:0] xResult1;
    wire [15:0] yResult1;
    
    wire [11:0] xInteger;
    wire [11:0] yInteger;
    
    wire [11:0] halfWidth = width_in >> 1;
    wire [11:0] halfHeight = height_in >> 1;
    
    // drop upper Q bits (max width is 2048... 2^11) not a problem for 640x480 vga output
    wire [15:0] fixedPointHalfWidth = {halfWidth, {Q{1'b0}}};
    wire [15:0] fixedPointHalfHeight = {halfHeight, {Q{1'b0}}};
    
    // multiply x cord
     qmult #(
        .Q(Q),
       .N(N)) mult1x(fixedPointHalfWidth,vector_in[47:32],xResult1);
       
     qmult #(
         .Q(Q),
        .N(N)) mult1y(fixedPointHalfHeight,vector_in[31:16],yResult1);
        
     //drop lower bits (Q bits) to get an 11 bit integer
     //TODO (just messed with this) (Q+1) opposed to Q
     assign xInteger = xResult1[N-1:Q+1];
     assign yInteger = yResult1[N-1:Q+1];
     
     //add half the size to make indices positive
     assign xpix_out = xInteger + halfWidth;
     assign ypix_out = yInteger + halfHeight;
     
     //on_screen is high only when x and y values are between 0 and width/height.
     assign on_screen_out = (xpix_out < width_in) || (xpix_out >=0) || (ypix_out < height_in) || (ypix_out >= 0);
     
    
endmodule
