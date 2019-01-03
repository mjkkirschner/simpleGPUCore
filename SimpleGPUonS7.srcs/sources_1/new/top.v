`timescale 1ns / 1ps

module top(
        input CLK100MHZ,
        
        output VGA_HS_O,
        output VGA_VS_O,
        output VGA_R,
        output VGA_G,
        output VGA_B
    );
    
    wire i_clk = CLK100MHZ;
    
    reg we_ = 1;

    reg [13:0] romAddressLines = 0;
      
    reg [Nbit-1:0] romDataLines = 0;
    
    wire [Nbit-1:0] vertDataOut;
    //single buffer xyz
    reg [(Nbit*3)-1:0] vertexBuffer = 0;
    reg[(Nbit*4)-1:0] vertex = 0;
    
    //TODO - maybe remove after vert data comes from external source
    reg [32:0] iterationCounter = 0;
    reg [15:0] vertCounter = 0;
    reg [8:0] stateCounter = 0;
    
    reg vertexReady = 0;
    //TODO this will be ready when matrix buffer is full.
    reg matrixReady = 1;
     
     //projection regs
    reg startProjection = 0;
    //16 x 16 matrix
    reg [(Nbit*16)-1:0] mvp_in = 512'b10000000000000001011010100000100000000000000000000000000000000001000000000000000101101010000010000000000000000000000000000000000100000000000000010001011010110010000000000000001000101101011001000000000000000001000101101011001000000000000000000000000000000001000000000000000101110001100000010000000000000001011100011000000000000000000000010111000110000000000000000001000010100110100100010000000000000001001001111001101100000000000000010010011110011010000000000000000100100111100110100000000000010001010100100000110;
    wire [(Nbit*3)-1:0] projected_vector;
    wire projection_done;
    
    //viewToScreen regs
    localparam SCREEN_WIDTH = 640;
    localparam Qbit = 16;
    localparam Nbit = 32;
    reg  [11:0 ]width = 640;
    reg  [11:0 ]height = 480;
    
    wire  [11:0] xpixel;
    wire  [11:0] ypixel;
    wire pixelOnScreen;
    
    //framebuffer regs
    reg [18:0] frameBufferAddressLines1 = 0;
    reg [18:0] frameBufferAddressLines2 = 0;
    reg  frameBufferData = 1; 
    reg frameBuffer_we_ = 1;
    wire frameBufferDataOut1;
    wire frameBufferDataOut2;
    
    //memory address regs
    reg [19:0] memoryAddress = 0;
    
    //vga data
    wire hs;
    wire vs;
    wire [9:0] xvga;
    wire [8:0] yvga;
    reg [15:0] cnt = 0;
    reg pix_stb = 0;
    reg outputColorReg = 0;
    
    //TODO do we need to reverse the bit format in the ram modules?
 
 
    staticRamDiscretePorts #(.ROMFILE("testVertexData.mem"),.DATA_WIDTH(32),.ADDR_WIDTH(14)) externalVertexDataROM (
                     .address(romAddressLines),
                      .data(romDataLines), 
                       .we_(we_),
                        .clock(i_clk),
                       .Q(vertDataOut));
               
   
   
    /*
       localparam SCREEN_HEIGHT = 480;
       localparam VRAM_DEPTH = SCREEN_WIDTH * SCREEN_HEIGHT; 
       localparam VRAM_A_WIDTH = 19;  // 2^18 > 640 x 360
       localparam VRAM_D_WIDTH = 1;   // colour bits per pixel
    
   sram #(
              .ADDR_WIDTH(VRAM_A_WIDTH), 
              .DATA_WIDTH(VRAM_D_WIDTH), 
              .DEPTH(VRAM_DEPTH), 
              .MEMFILE("framebuffer.mem"))  // bitmap to load
              vram (
              .i_addr(frameBufferAddressLines2), 
              .i_clk(i_clk), 
              .i_write(0),  // we're always reading
              .i_data(0), 
              .o_data(frameBufferDataOut2)
          );
        */
          
   dualPortStaticRam #(.ROMFILE("framebuffer.mem"),.DATA_WIDTH(1),.ADDR_WIDTH(19)) frameBuffer (
                       .address_1(frameBufferAddressLines1),
                       .address_2(frameBufferAddressLines2),
                        .data(frameBufferData), 
                         .we_(frameBuffer_we_),
                         .clock(i_clk),
                         .clock2(i_clk),
                         .Q_1(frameBufferDataOut1),
                         .Q_2(frameBufferDataOut2));


                       
        vert_projector #(.Q(Qbit),.N(Nbit)) 
               projector(.i_clk(i_clk),
                    .in_start(startProjection),
                    .mvp_in( mvp_in),
                   .vertex_in(vertex),
                   .out_vector( projected_vector),
                   .out_done(projection_done)
                   );
                   
     ViewToScreenConverter#(.Q(Qbit),.N(Nbit))
                viewToScreen(.width_in(width),
                             .height_in(height),
                             .vector_in(projected_vector),
                             .xpix_out(xpixel),
                             .ypix_out(ypixel),
                             .on_screen_out(pixelOnScreen));
                             
   vgaSignalGenerator vgaPart (
                         .i_clk(i_clk),
                         .i_pix_stb(pix_stb),
                         .o_hs(hs),
                         .o_vs(vs),
                         .o_x(xvga),
                         .o_y(yvga)
                     );
                                         
                           assign VGA_HS_O = hs;
                           assign VGA_VS_O = vs;
                           assign VGA_R = outputColorReg;
                           assign VGA_G = outputColorReg;
                           assign VGA_B = outputColorReg;
 
      
   //on each clock - increment the counter and grab more data from ram.
   //TODO a state machine would work well for this...
   always@(posedge i_clk) begin
       
       {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000
       iterationCounter <= iterationCounter + 1;
       //TODO try moving this inside a 25mhz clock
       frameBufferAddressLines2 <= (yvga * SCREEN_WIDTH) + xvga;
       outputColorReg <= frameBufferDataOut2;
      
       //~3mhz
           if(pix_stb) begin
           
                // check that we are not over indexed // TOOD - this will be removed later.
                   if(vertCounter < 3644) begin
                        
                            //build up the vertex buffer
                            //GET X
                            if(stateCounter == 0) begin
                                //save data from ram shifted into the buffer.
                                 vertexBuffer <= {vertexBuffer[(Nbit*2)-1:0],vertDataOut};
                                stateCounter <= stateCounter + 1;
                            end
                            
                            if(stateCounter == 1) begin
                             //increment address lines for next vertex.
                               romAddressLines <= romAddressLines +1;
                               stateCounter <= stateCounter + 1;
                            end
                                //GET Y
                              if(stateCounter == 2) begin
                                  //save data from ram shifted into the buffer.
                                   vertexBuffer <= {vertexBuffer[(Nbit*2)-1:0],vertDataOut};
                                  stateCounter <= stateCounter + 1;
                             end
                             if(stateCounter == 3) begin                
                              //increment address lines for next vertex.
                                romAddressLines <= romAddressLines +1;  
                                stateCounter <= stateCounter + 1;       
                             end       
                               //GET Z                                 
                             if(stateCounter == 4) begin
                              //save data from ram shifted into the buffer.
                               vertexBuffer <= {vertexBuffer[(Nbit*2)-1:0],vertDataOut};
                              stateCounter <= stateCounter + 1;
                         end
                         //TODO do we want to do this here for the next vert?
                          if(stateCounter == 5) begin                
                          //increment address lines for next vertex.
                            romAddressLines <= romAddressLines +1;  
                            stateCounter <= stateCounter + 1;       
                         end       
                            
                            
                            // append W - and set the states.
                            if (stateCounter == 6) begin
                                vertCounter <= vertCounter + 1;
                                vertex <= {vertexBuffer,{Qbit-1{1'b0}},1'b1,{Qbit{1'b0}}};
                                vertexReady <= 1;
                                stateCounter <= 7;
                            end
                            
                            // in state 4 - we are done buffering and are starting to project.
                            if(stateCounter ==7 && vertexReady ==1 && matrixReady == 1) begin
                                startProjection <= 1;
                                 stateCounter <= 8;
                              end
                            
                            // projection just finished, reset some state and 
                            // draw the vertex.
                            if(stateCounter >7 && stateCounter <100 && projection_done == 1) begin
                                //lets wait here for another 15 cycles
                                //TODO make this more easily adjustable.
                                stateCounter <= stateCounter+1;
                            end
                            
                            //TODO lets assume pixel calculations are done
                            //so now map to memory and write to the framebuffer.
                            //
                            if(stateCounter == 100) begin
                                #5 $display("vertexcount %d, should display at coord x %d, y %d ",vertCounter,xpixel,ypixel );
                                memoryAddress <= xpixel + (ypixel * width);
                                frameBufferAddressLines1 <= memoryAddress;
                                stateCounter <= 101;
                            end
                            
                            // actually write a one into memory if the pixel is
                            // visible - else give do nothing.
                             if(stateCounter == 101) begin
                             //assert the write bit for a clock.
                             if(pixelOnScreen ==1) begin
                                frameBuffer_we_ = 0;
                                end
                               stateCounter <= 102;
 
                            end
                            
                            //we're done - reset all state
                            if(stateCounter == 102) begin
                                frameBuffer_we_ <= 1;
                                stateCounter <= 0;
                                vertexReady <= 0;
                                startProjection <= 0;

                            end
                            
                   end
            end
            
    end

endmodule
