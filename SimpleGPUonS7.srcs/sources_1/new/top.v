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
    
    reg cs_ = 0;
    reg we_ = 1;
    reg oe_ = 0;

    reg [13:0] romAddressLines = 0;
    reg [15:0] romDataLines = 0;
    
    wire [15:0] vertDataOut;
    //single buffer xyz
    reg [47:0] vertexBuffer = 0;
    reg[63:0] vertex = 0;
    
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
    reg [255:0] mvp_in = 256'b1000000000001111100000000000001010000000000000101000000000000010000000000000000000000000000011111000000000001110100000000000101110000000000000110000000000001110000000000000111000000000000010111000000000000000000000000000000000000000011001100000000001110010;
    wire [47:0] projected_vector;
    wire projection_done;
    
    //viewToScreen regs
    localparam SCREEN_WIDTH = 640;
    reg [11:0 ]width = 640;
    reg [11:0 ]height = 480;
    
    wire [11:0] xpixel;
    wire [11:0] ypixel;
    wire pixelOnScreen;
    
    //framebuffer regs
    reg [18:0] frameBufferAddressLines1 = 0;
    reg [18:0] frameBufferAddressLines2 = 0;
    reg  frameBufferData = 1; 
    reg frameBuffer_cs_ = 0;
    reg frameBuffer_we_ = 1;
    reg frameBuffer_oe_ = 0;
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
    
    //TODO do we need to reverse the bit format in the ram modules?
 
 /*
    staticRamDiscretePorts #(.ROMFILE("testVertexData.mem"),.DATA_WIDTH(16),.ADDR_WIDTH(14)) externalVertexDataROM (
                     .address(romAddressLines),
                      .data(romDataLines), 
                      .cs_(cs_),
                       .we_(we_),
                       .oe_(oe_),
                        .clock(i_clk),
                       .Q(vertDataOut));
   */                    
   dualPortStaticRam #(.ROMFILE("framebuffer.mem"),.DATA_WIDTH(1),.ADDR_WIDTH(18)) frameBuffer (
                       .address_1(frameBufferAddressLines1),
                       .address_2(frameBufferAddressLines2),
                        .data(frameBufferData), 
                        .cs_(frameBuffer_cs_),
                         .we_(frameBuffer_we_),
                         .oe_(frameBuffer_oe_),
                         .clock(i_clk),
                         .clock2(i_clk),
                         .Q_1(frameBufferDataOut1),
                         .Q_2(frameBufferDataOut2));
     /*                  
        vert_projector #(.Q(4),.N(16)) 
               projector(.i_clk(i_clk),
                    .in_start(startProjection),
                    .mvp_in( mvp_in),
                   .vertex_in(vertex),
                   .out_vector( projected_vector),
                   .out_done(projection_done)
                   );
                   
     ViewToScreenConverter#(.Q(4),.N(16))
                viewToScreen(.width_in(width),
                             .height_in(height),
                             .vector_in(projected_vector),
                             .xpix_out(xpixel),
                             .ypix_out(ypixel),
                             .on_screen_out(pixelOnScreen));
       */                      
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
                           assign VGA_R = frameBufferDataOut2;
                           assign VGA_G = frameBufferDataOut2;
                           assign VGA_B = frameBufferDataOut2;
    /*                       
                           //width and height are 16 bit integers (really 11)
                           input [11:0] width_in,
                           input [11:0] height_in,
                           //vector format [16bit,16,16] - each component is [1signbit,11databits,4Qbits]
                           input [47:0] vector_in,
                           
                           output [11:0] xpix_out,
                           output [11:0] ypix_out,
                           output on_screen_out
                   
                       );
    */
      
   //on each clock - increment the counter and grab more data from ram.
   //TODO a state machine would work well for this...
   always@(posedge i_clk) begin
       
       {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000
       iterationCounter <= iterationCounter + 1;
       //TODO try moving this inside a 25mhz clock
       frameBufferAddressLines2 <= (yvga * SCREEN_WIDTH) + xvga;
  
  /*     
       //~3mhz
           if(iterationCounter[4] == 1) begin
           
                // check that we are not over indexed // TOOD - this will be removed later.
                   if(vertCounter < 3644) begin
                        
                            //build up the vertex buffer
                            if(stateCounter < 3) begin

                                //save data from ram shifted into the buffer.
                                 vertexBuffer <= {vertexBuffer[47-15:0],vertDataOut};
                                //increment address lines for next vertex.
                                romAddressLines <= romAddressLines +1;
                                stateCounter <= stateCounter + 1;
                            end
                            
                            // append W - and set the states.
                            if (stateCounter == 3) begin
                                vertCounter <= vertCounter + 1;
                                vertex <= {vertexBuffer,16'b0000000000010000};
                                vertexReady <= 1;
                                stateCounter <= 4;
                            end
                            
                            // in state 4 - we are done buffering and are starting to project.
                            if(stateCounter ==4 && vertexReady ==1 && matrixReady == 1) begin
                                startProjection <= 1;
                                 stateCounter <= 5;
                              end
                            
                            // projection just finished, reset some state and 
                            // draw the vertex.
                            if(stateCounter ==5 && projection_done == 1) begin
                                
                                stateCounter <= 6;
                            end
                            
                            //TODO lets assume pixel calculations are done
                            //so now map to memory and write to the framebuffer.
                            //
                            if(stateCounter == 6) begin
                                #5 $display("vertexcount %d, should display at coord x %d, y %d ",vertCounter,xpixel,ypixel );
                                memoryAddress = xpixel + (ypixel * width);
                                frameBufferAddressLines1 = memoryAddress;
                                stateCounter <= 7;
                            end
                            
                            // actually write a one into memory if the pixel is
                            // visible - else give do nothing.
                             if(stateCounter == 7) begin
                             //assert the write bit for a clock.
                             if(pixelOnScreen ==1) begin
                                frameBuffer_we_ = 0;
                                end
                               stateCounter <= 8;
 
                            end
                            
                            //we're done - reset all state
                            if(stateCounter == 8) begin
                                frameBuffer_we_ <= 1;
                                stateCounter <= 0;
                                vertexReady <= 0;
                                startProjection <= 0;

                            end
                            
                   end
            end
            */
    end

endmodule
