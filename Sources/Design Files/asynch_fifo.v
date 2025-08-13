`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2025 17:28:55
// Design Name: 
// Module Name: asynch_fifo
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
module dff(input clk, input [4:0]d, input rst, output reg [4:0]q);
    always@(posedge clk or posedge rst)begin
        if(rst)
            q<=0;
        else
            q<=d;
    end
endmodule


module g2b(input [4:0]gr, output reg [4:0]bin);
    integer i=0,w=0;
    always@(gr)begin
        bin[4]=gr[4];
        for(i=3;i>=0;i=i-1)begin
            bin[i]=bin[i+1]^gr[i];
        end
    end
endmodule
    


module asynch_fifo(input rst, input wr_clk, input rd_clk,
                input rd_en, input wr_en, input [7:0]data_in,
                output full, output empty, output reg [7:0] data_out
    );
    
    parameter dep=16,add=4,width=7;
    
    wire [add:0]q1,q2;
    wire [add:0]w_ptr_rg, r_ptr_wg, w_ptr_rb, r_ptr_wb;
    
    reg [add:0]w_ptrb, r_ptrb;
    reg [width:0]mem[0:dep-1];
    wire [add:0]w_ptrg, r_ptrg;
    
    //.......Double Flop Synchronizer for write and read pointer
    
    dff d1(.clk(rd_clk),.d(w_ptrg),.q(q1),.rst(rst));
    dff d2(.clk(rd_clk),.d(q1),.q(w_ptr_rg),.rst(rst));
    dff d3(.clk(wr_clk),.d(r_ptrg),.q(q2),.rst(rst));
    dff d4(.clk(wr_clk),.d(q2),.q(r_ptr_wg),.rst(rst));
    
    //.......Binary to gray convertion for write and read pointer
    
    assign w_ptrg=(w_ptrb>>1)^w_ptrb;
    assign r_ptrg=(r_ptrb>>1)^r_ptrb;
    
    //........Gray to binary convertion after synchronization
    
    g2b g1(.gr(w_ptr_rg),.bin(w_ptr_rb));
    g2b g2(.gr(r_ptr_wg),.bin(r_ptr_wb));
    
    //.......Empty logic at read side and Full logic at write side
    
    assign empty=(w_ptr_rb==r_ptrb);
    assign full=(~w_ptrb[add]==r_ptr_wb[add])&(w_ptrb[add-1:0]==r_ptr_wb[add-1:0]);
    
    
    //.......Write logic
    
    always@(posedge wr_clk or posedge rst)begin
        
        if(rst)begin
            w_ptrb<=0;
        end
        else begin
            if(wr_en&~full)begin
                mem[w_ptrb[add-1:0]]<=data_in;
                w_ptrb<=w_ptrb+1;
            end
        end
    end
    
    //...........Read logic
    
    always@(posedge rd_clk or posedge rst)begin
        
        if(rst)begin
            r_ptrb<=0;
            data_out <= 0;
        end
        else begin
            if(rd_en&~empty)begin
                data_out<=mem[r_ptrb[add-1:0]];
                r_ptrb<=r_ptrb+1;
            end
        end
    end
    
    
endmodule



