`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/16/2018 12:29:25 PM
// Design Name: 
// Module Name: matrix4x4x1
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


module matrix4x4x1(
    input [0:255] mvp_in,
    input [0:63] vertex_in,
    output reg [0:63] result
    );
    
    parameter Q = 8;
    parameter N = 16;
    
    //internal variables
    reg [0:15] mvp_inTemp[0:15][0:15];
    reg [0:15] vertex_inTemp[0:3];
    reg [0:15] res_Temp [0:3];
    
    reg[0:16] tempx1;
    reg[0:16] tempx2;
    reg[0:16] tempx3;
    reg[0:16] tempx4;
    
    reg[0:16] tempy1;
    reg[0:16] tempy2;
    reg[0:16] tempy3;
    reg[0:16] tempy4;
    
    reg[0:16] tempz1;
    reg[0:16] tempz2;
    reg[0:16] tempz3;
    reg[0:16] tempz4;

    reg[0:16] tempw1;
    reg[0:16] tempw2;
    reg[0:16] tempw3;
    reg[0:16] tempw4;
    
    integer i,j = 0;
    
    
    //TODO I think matrix[row][col] is correct.
    
     //calculate x component of result vector
     qmult #(
     .Q(Q),
    .N(N)) mult1x(mvp_inTemp[0][0],vertex_inTemp[0],tempx1);
    
      qmult #(
       .Q(Q),
      .N(N)) mult12x(mvp_inTemp[0][1],vertex_inTemp[1],tempx2);
      
      qadd #(
          .Q(Q),
         .N(N)) add2x(tempx2,tempx1,res_Temp[0]);

     qmult #(
     .Q(Q),
    .N(N)) mult3x(mvp_inTemp[0][2],vertex_inTemp[2],tempx3);
    
    qadd #(
        .Q(Q),
       .N(N)) add3x(res_Temp[0],tempx3,res_Temp[0]);
    
    qmult #(
       .Q(Q),
      .N(N)) mult4x(mvp_inTemp[0][3],vertex_inTemp[3],tempx4);
      
      qadd #(
          .Q(Q),
         .N(N)) add4x(res_Temp[0],tempx4,res_Temp[0]);   
    
    
    //calculate y component of result vector
              qmult #(
              .Q(Q),
             .N(N)) mult1y(mvp_inTemp[1][0],vertex_inTemp[0],tempy1);
             
               qmult #(
                .Q(Q),
               .N(N)) mult12y(mvp_inTemp[1][1],vertex_inTemp[1],tempy2);
               
               qadd #(
                   .Q(Q),
                  .N(N)) add2y(tempy2,tempy1,res_Temp[1]);
         
              qmult #(
              .Q(Q),
             .N(N)) mult3y(mvp_inTemp[1][2],vertex_inTemp[2],tempy3);
             
             qadd #(
                 .Q(Q),
                .N(N)) add3y(res_Temp[1],tempy3,res_Temp[1]);
             
             qmult #(
                .Q(Q),
               .N(N)) mult4y(mvp_inTemp[1][3],vertex_inTemp[3],tempy4);
               
               qadd #(
                   .Q(Q),
                  .N(N)) add4y(res_Temp[1],tempy4,res_Temp[1]); 
    
   
    //calculate z component of result vector
     qmult #(
     .Q(Q),
    .N(N)) mult1z(mvp_inTemp[1][0],vertex_inTemp[0],tempz1);
    
      qmult #(
       .Q(Q),
      .N(N)) mult12z(mvp_inTemp[1][1],vertex_inTemp[1],tempz2);
      
      qadd #(
          .Q(Q),
         .N(N)) add2z(tempz2,tempz1,res_Temp[2]);

     qmult #(
     .Q(Q),
    .N(N)) mult3z(mvp_inTemp[1][2],vertex_inTemp[2],tempz3);
    
    qadd #(
        .Q(Q),
       .N(N)) add3z(res_Temp[2],tempz3,res_Temp[2]);
    
    qmult #(
       .Q(Q),
      .N(N)) mult4z(mvp_inTemp[1][3],vertex_inTemp[3],tempz4);
      
      qadd #(
          .Q(Q),
         .N(N)) add4z(res_Temp[2],tempz4,res_Temp[2]);    
    
    
   //calculate w component of result vector
             qmult #(
             .Q(Q),
            .N(N)) mult1w(mvp_inTemp[1][0],vertex_inTemp[0],tempw1);
            
              qmult #(
               .Q(Q),
              .N(N)) mult12w(mvp_inTemp[1][1],vertex_inTemp[1],tempw2);
              
              qadd #(
                  .Q(Q),
                 .N(N)) add2w(tempw2,tempw1,res_Temp[3]);
        
             qmult #(
             .Q(Q),
            .N(N)) mult3w(mvp_inTemp[1][2],vertex_inTemp[2],tempw3);
            
            qadd #(
                .Q(Q),
               .N(N)) add3w(res_Temp[3],tempw3,res_Temp[3]);
            
            qmult #(
               .Q(Q),
              .N(N)) mult4w(mvp_inTemp[1][3],vertex_inTemp[3],tempw4);
              
              qadd #(
                  .Q(Q),
                 .N(N)) add4w(res_Temp[3],tempw4,res_Temp[3]);      
    
    
       
    
    always@(mvp_in,vertex_in) begin
     //convert 1d to 3d
     //TODO consider row v col.

       //(matrix[row][col]
       { mvp_inTemp[0][0],mvp_inTemp[0][1],mvp_inTemp[0][2],mvp_inTemp[0][3],
       mvp_inTemp[1][0],mvp_inTemp[1][1],mvp_inTemp[1][2],mvp_inTemp[1][3],
       mvp_inTemp[2][0],mvp_inTemp[2][1],mvp_inTemp[2][2],mvp_inTemp[2][3],
       mvp_inTemp[3][0],mvp_inTemp[3][1],mvp_inTemp[3][2],mvp_inTemp[3][3] } = mvp_in;
       
       {vertex_inTemp[0],vertex_inTemp[1],vertex_inTemp[2],vertex_inTemp[3]} = vertex_in;
       

                   
                   
        //TODO(could use a generate loop)
        //makes assumption i iterates column, j iterates rows
       // for(i = 0; i<4; i= i + 1)
          //  for(j=0;j <4; j = j +1)
         ///  
         //   
        //
        //        res_Temp[i] = res_Temp[i] + mvp_inTemp[i][j] * vertex_inTemp[j];
                
                //flatten result back to 1d vector (4 * 16 bits)
        result = {res_Temp[0],res_Temp[1],res_Temp[2],res_Temp[3]};
    end
    
    
endmodule
