`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/07 18:40:37
// Design Name: 
// Module Name: Russian_roulette
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


module Russian_roulette(
    input clk,
    input [5:0] encoderInput,
    input [2:0] directLocation,
    input auto,
    input start,
    input reset,
    input random_btn,
    output [2:0]counterV,
    output [2:0]dff_out,
    output [2:0] muxOut,
    output [2:0] encoderOut,
    output [2:0] compare,
    output [2:0] d,
    output isBullet
    );
    
    //wire [2:0] counterV;
    
    binaryCounter bnrC(clk, reset, counterV[2:0]);
    
    //wire [2:0]d;
    multiplexor2to1 dmux2(start, dff_out[2], counterV[2], random_btn, d[2]);
    multiplexor2to1 dmux1(start, dff_out[1], counterV[1], random_btn, d[1]);
    multiplexor2to1 dmux0(start, dff_out[0], counterV[0], random_btn, d[0]);
    
    
    //wire [2:0] dff_out;
    
    D_flipflop d_ff2(.reset(reset),.d(d[2]), .clk(clk), .q(dff_out[2]));
    D_flipflop d_ff1(.reset(reset),.d(d[1]), .clk(clk), .q(dff_out[1]));
    D_flipflop d_ff0(.reset(reset),.d(d[0]), .clk(clk), .q(dff_out[0]));
    
    //wire [2:0] muxOut;
    
    multiplexor2to1 MUX2(start, directLocation[2], dff_out[2], auto, muxOut[2]);
    multiplexor2to1 MUX1(start, directLocation[1], dff_out[1], auto, muxOut[1]);
    multiplexor2to1 MUX0(start, directLocation[0], dff_out[0], auto, muxOut[0]);
    
    //wire [2:0] encoderOut;
    
    encoder enc(encoderInput[5:0], encoderOut[2:0]);
    
    //wire [2:0] compare;
    
    xnor(compare[2], muxOut[2], encoderOut[2]);
    xnor(compare[1], muxOut[1], encoderOut[1]);
    xnor(compare[0], muxOut[0], encoderOut[0]);
    
    //assign isBullet = compare[2]&compare[1]&compare[0];
    and(isBullet, compare[2], compare[1], compare[0]);
    
endmodule

module binaryCounter(
    input clk,
    input reset,
    output [2:0] count
);  

    wire [2:0] t_in;
    wire c2SUMc1;
    //assign t_in[2] = count[0] && (count[2]||count[1]);
    or(c2SUMc1, count[2], count[1]);
    and(t_in[2], count[0], c2SUMc1);
    
    wire c2_n;
    //assign t_in[1] = (~count[2]) && count[0];
    not(c2_n, count[2]);
    and(t_in[1], c2_n, count[0]);
    
    //assign t_in[0] = 1;
    or(t_in[0], 1, 1);
    
    /*
    always @(posedge clk) begin
        if (reset)
            count <= 3'b000;
        else begin
            if (t_in[0]) count[0] <= ~count[0];
            if (t_in[1]) count[1] <= ~count[1];
            if (t_in[2]) count[2] <= ~count[2];
        end
    end
    */
    
    T_flipflop TFF2(reset, t_in[2], clk, count[2]);
    T_flipflop TFF1(reset, t_in[1], clk, count[1]);
    T_flipflop TFF0(reset, t_in[0], clk, count[0]);
    
endmodule

module T_flipflop(input reset, input t, input clk, output reg q);
    initial begin
        q = 0;
    end

    always @(posedge clk) begin
        /*if (reset) q <= 0;
        else if (t) q <= ~q;*/
        q <= ~reset & (q ^ t);
    end
endmodule

module D_flipflop(input reset, input d, input condition, input clk, output reg q);
    initial begin
        q = 0;
    end
    
    always @(posedge clk) begin
        /*if (reset) q <= 0;
        else q <= d;*/
        q <= ~reset & d;
    end
endmodule

module multiplexor2to1(
    input en,
    input i0,
    input i1,
    input select,
    output q
);
    wire muxV;
    wire [1:0]minterm;
    wire select_n;
    //assign q = en && ((i0&&(~select))||(i1&&select));
    not(select_n, select);
    and(minterm[0], i0, select_n);
    and(minterm[1], i1, select);
    or(muxV, minterm[0], minterm[1]);
    and(q, en, muxV);

endmodule

module encoder(
    input [5:0] inV,
    output [2:0] outV
);
    wire en;
    wire en_n;
    
    or(en, inV[5], inV[4], inV[3], inV[2], inV[1], inV[0]);
    not(en_n, en);
    
    //assign outV[2] = (~en) || (inV[5] || inV[4]);
    or(outV[2], en_n, inV[5], inV[4]);
    
    //assign outV[1] = (~en) || (inV[3] || inV[2]);
    or(outV[1], en_n, inV[3], inV[2]);
    
    //assign outV[0] = (~en) || (inV[1] || inV[3] || inV[5]);
    or(outV[0], en_n, inV[1], inV[3], inV[5]);
endmodule

/*module sr_latch(
    input s,r,
    output q, q_
);
    nor(q, r, q_);
    nor(q_, s, q);    

endmodule

module D_FlipFlop(
    input reset,
    input clk,
    input D,
    output Q
);

    wire D_;
    not(D_, D);
    wire inS, inR;
    
    and(inS, clk, D);
    and(inR, clk, D_);
    
    sr_latch srL(inS&~reset, inR|reset, Q);

endmodule*/
