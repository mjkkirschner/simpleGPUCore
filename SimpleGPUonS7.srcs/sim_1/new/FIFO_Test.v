`timescale 1ns / 1ps

module FIFO_Test;

        //inputs
        reg [15:0] inputData = 0;
        wire [15:0] outputData;

        reg clock = 0;
        wire reset = 0;
        reg readVertex = 0;
        reg writeVertex = 0;
        wire empty;
        wire full;
        
         FIFO#(.DATA_WIDTH(16),.RAM_DEPTH(3))
         
          uut (        
              .clk_i(clock),
              .reset_i(reset),
              .data_i(inputData),
              .r_en_i(readVertex),
              .w_en_i(writeVertex),
              .data_o(outputData),
              .empty_o(empty),
              .full_o(full));
              
            initial begin 
                         $monitor ("input: %b, output: %b, empty %b, full %b", inputData, outputData, empty, full);        //Monitor the stuff we care about
                         
                         //first input data word
                         #10 inputData = 16'b0000000000000001;
                         
                         //assert write
                         #10 writeVertex = 1;
                         
                         //change data
                         #10 inputData =  16'b0000000000000010;
                         
                           //change data
                         #10 inputData =  16'b0000000000000011;
                         
                          //assert write off
                          #10 writeVertex = 0;
                          #100 readVertex = 1;
                          
                    end
                    
                    
            always begin
             #5  clock =  ! clock; 
            end
                         
endmodule
