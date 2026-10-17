`timescale 1ns / 1ps


module FinalProject_fpga(
    input clk,
    input btnCenter,
    input btnTop,
    input btnBottom,
    input btnLeft,
    input btnRight,
    input [15:0] sw,
    output [3:0] ssSel,
    output [7:0] ssDisp,
    output [15:0] led
    );


  wire random_btn;
  wire start;
  wire [5:0] encoderIn;
  wire [2:0] directLocation;
  wire [2:0] counterV;
  wire reset;
  wire auto;
  wire [2:0] state;
  wire bulletFound;
  ////////////////
  wire resetV;
  wire [2:0]dff_out;
  //reg reset;
  ///////////////
  
  wire [15:0] gbuf; //15~12: 첫번째 seg의 값
  wire [3:0] res; //각 seg 지칭
  wire c_out;
   
  
  
  Russian_roulette roulette(
      .clk(clk),
      .encoderInput(sw[5:0]),
      .directLocation(sw[8:6]),
      .auto(auto),
      .random_btn(random_btn),
      .start(sw[15]),
      .reset(btnCenter),
      .dff_out(dff_out),
      .isBullet(bulletFound),
      .counterV(counterV)
);
    
    //reg game_reset = 1'b1;
    //wire in_reset;
    //assign in_reset = 1'b1;
    
    
    assign led[15] = bulletFound;
    assign led[14] = auto;
    assign led[13] = random_btn;
    
    
    assign gbuf[14] = (~state[2]) && (~state[1]) && (~state[0]);
    assign gbuf[13] = (~state[2]) && (~state[1]) && (~state[0]);
    assign gbuf[12] = (~state[2]) && (~state[1]) && (~state[0]);
    assign gbuf[11] = (~state[2]) && (~state[1]) && (~state[0]);
    assign gbuf[7] = (~state[2]) && (~state[1]) && (~state[0]);
    assign gbuf[4] = (~state[2]) && (~state[1]) && (~state[0]);
    assign gbuf[3] = (~state[2]) && (~state[1]) && (~state[0]);
    //assign gbuf[3] = 0;
    
    assign auto = sw[14];
    
    
    assign gbuf[15] = 0;
    assign gbuf[10] = 0;
    assign gbuf[9] = 0;
    assign gbuf[8] = 0;
    assign gbuf[6] = 0;
    assign gbuf[5] = 0;
    
    assign gbuf[2] = state[2];
    //assign gbuf[2] = dff_out[2];
    assign gbuf[1] = state[1] || ((~state[2])&&(~state[0]));
    //assign gbuf[1] = dff_out[1];
    assign gbuf[0] = state[0];
    //assign gbuf[0] = dff_out[0];
    
    
    bullet_saver(.f(bulletFound), .clk(clk), .reset(btnCenter), .encoderIn(sw[5:0]), .bullet_count(state));
    
    /*always @(posedge clk) begin
        random_btn <= btnLeft;
    end*/
    assign random_btn = btnLeft;
    
  led_renderer renderer (
      .graphics(gbuf),
      .clk(clk),
      .segSel(ssSel),
      .seg(ssDisp)
  );
   
endmodule

module led_renderer (
    input [15:0] graphics,
    input clk,
    output reg [3:0] segSel,
    output reg [7:0] seg
);
  integer counter2;
  wire [7:0] res0, res1, res2, res3; //seg 각각의 값

  initial begin
    segSel <= 14;
    seg <= 8'b11111111;
  end

  bcd_to_7seg pos0 (
      .bcd(graphics[3:0]),
      .seg(res3)
  );
  bcd_to_7seg pos1 (
      .bcd(graphics[7:4]),
      .seg(res2)
  );
  bcd_to_7seg pos2 (
      .bcd(graphics[11:8]),
      .seg(res1)
  );
  bcd_to_7seg pos3 (
      .bcd(graphics[15:12]),
      .seg(res0)
  );
  
  always @(posedge clk) begin
    counter2 <= counter2 + 1;
    if (counter2 == 100000) begin
      counter2 <= 0;
      case (segSel)
        14: begin
          segSel <= 13;
          seg <= res1;
        end
        13: begin
          segSel <= 11;
          seg <= res2;
        end
        11: begin
          segSel <= 7;
          seg <= res3;
        end
        7: begin
          segSel <= 14;
          seg <= res0;
        end
      endcase
    end
  end

endmodule


module bcd_to_7seg (
    input [3:0] bcd,
    output reg [7:0] seg
);

  always @(*) begin
    // dot, center, tl, bl, b, br, tr, t
    case (bcd)
      4'b0000: seg = 8'b11000000;  // 0
      4'b0001: seg = 8'b11111001;  // 1
      4'b0010: seg = 8'b10100100;  // 2
      4'b0011: seg = 8'b10110000;  // 3
      4'b0100: seg = 8'b10011001;  // 4
      4'b0101: seg = 8'b10010010;  // 5
      4'b0110: seg = 8'b10000010;  // 6
      4'b0111: seg = 8'b11000111;  // 7 L
      4'b1000: seg = 8'b11000000;  // 8 O
      4'b1001: seg = 8'b10010010;  // 9 S
      4'b1010: seg = 8'b10000110;  // A E
      4'b1011: seg = 8'b10101111;  // r
      4'b1100: seg = 8'b11000010;  // g
      4'b1101: seg = 8'b10000110;  // E
      4'b1110: seg = 8'b10110111;  // =
      4'b1111: seg = 8'b11111111;  // off
      default: seg = 8'b11111111;
    endcase
  end
endmodule

module bullet_saver(
    input f,
    input clk,
    input reset,
    input [5:0] encoderIn ,
    output [2:0] bullet_count 
    );
    
    wire ischanged;
    detectEncoderChange change(
        .encoderInput(encoderIn),
        .clk(clk),
        .reset(reset),
        .detect_out(ischanged)
    );
    
    //initial bullet_count = 3'b000;
    
    wire T0 = (reset &  bullet_count[0])
            | (ischanged &  bullet_count[0])
            | (ischanged & ~f & ~reset &  bullet_count[1])
            | (ischanged & ~f & ~reset &  bullet_count[2]);
            
    wire T1 = (reset & ~bullet_count[1])
            | (ischanged &  f &  bullet_count[1] & ~reset)
            | (ischanged & ~reset &  bullet_count[1] & ~bullet_count[0])
            | (ischanged & ~f & ~reset &  bullet_count[2] & ~bullet_count[0]);
    
    wire T2 = (reset & ~bullet_count[2])
            | (ischanged &  f &  bullet_count[2] & ~reset)
            | (ischanged & ~f & ~reset & ~bullet_count[0] & ~bullet_count[1]);
            
    T_flipflop t_ff2(
    .reset(1'b0),
    .t(T2),
    .clk(clk),
    .q(bullet_count[2])
    );
    
    T_flipflop t_ff1(
    .reset(1'b0),
    .t(T1),
    .clk(clk),
    .q(bullet_count[1])
    );
    
    T_flipflop t_ff0(
    .reset(1'b0),
    .t(T0),
    .clk(clk),
    .q(bullet_count[0])
    );
      
endmodule

module detectEncoderChange (
    input [5:0]encoderInput,
    input clk,
    input reset,
    output detect_out
);
    /*wire [5:0]D_out;
    wire [5:0] en;
    wire [5:0] change;
    
    and(en[5], change[5], clk);
    and(en[4], change[4], clk);
    and(en[3], change[3], clk);
    and(en[2], change[2], clk);
    and(en[1], change[1], clk);
    and(en[0], change[0], clk);
    
    D_flipflop DFF6(.reset(reset), .d(encoderInput[5]), .clk(en[5]), .q(D_out[5]));
    D_flipflop DFF5(.reset(reset), .d(encoderInput[4]), .clk(en[4]), .q(D_out[4]));
    D_flipflop DFF4(.reset(reset), .d(encoderInput[3]), .clk(en[3]), .q(D_out[3]));
    D_flipflop DFF3(.reset(reset), .d(encoderInput[2]), .clk(en[2]), .q(D_out[2]));
    D_flipflop DFF2(.reset(reset), .d(encoderInput[1]), .clk(en[1]), .q(D_out[1]));
    D_flipflop DFF1(.reset(reset), .d(encoderInput[0]), .clk(en[0]), .q(D_out[0]));
    
    xor(change[5], D_out[5], encoderInput[5]);
    xor(change[4], D_out[4], encoderInput[4]);
    xor(change[3], D_out[3], encoderInput[3]);
    xor(change[2], D_out[2], encoderInput[2]);
    xor(change[1], D_out[1], encoderInput[1]);
    xor(change[0], D_out[0], encoderInput[0]);
    
    or(detect, change[5], change[4], change[3], change[2], change[1], change[0]);*/
    wire encoderInput_prev_5;
	wire encoderInput_prev_4;
	wire encoderInput_prev_3;
	wire encoderInput_prev_2;
	wire encoderInput_prev_1;
	wire encoderInput_prev_0;
	wire detect;
	
	D_flipflop d_ff5(
	.clk(clk),
	.reset(1'b0),
	.condition(1'b1),
	.d(encoderInput[5]),
	.q(encoderInput_prev_5)
	);
	
	D_flipflop d_ff4(
	.clk(clk),
	.reset(1'b0),
	.condition(1'b1),
	.d(encoderInput[4]),
	.q(encoderInput_prev_4)
	);
	
	D_flipflop d_ff3(
	.clk(clk),
	.reset(1'b0),
	.condition(1'b1),
	.d(encoderInput[3]),
	.q(encoderInput_prev_3)
	);
	
	D_flipflop d_ff2(
	.clk(clk),
	.reset(1'b0),
	.condition(1'b1),
	.d(encoderInput[2]),
	.q(encoderInput_prev_2)
	);

	D_flipflop d_ff1(
	.clk(clk),
	.reset(1'b0),
	.condition(1'b1),
	.d(encoderInput[1]),
	.q(encoderInput_prev_1)
	);

	D_flipflop d_ff0(
	.clk(clk),
	.reset(1'b0),
	.condition(1'b1),
	.d(encoderInput[0]),
	.q(encoderInput_prev_0)
	);
	
	wire detect5 = encoderInput[5] ^ encoderInput_prev_5;
	wire detect4 = encoderInput[4] ^ encoderInput_prev_4;
	wire detect3 = encoderInput[3] ^ encoderInput_prev_3;
	wire detect2 = encoderInput[2] ^ encoderInput_prev_2;
	wire detect1 = encoderInput[1] ^ encoderInput_prev_1;
	wire detect0 = encoderInput[0] ^ encoderInput_prev_0;

    wire all_zero;
    
    assign all_zero = encoderInput[5]|encoderInput[4]|encoderInput[3]|encoderInput[2]|encoderInput[1]|encoderInput[0];
	assign detect = detect5 | detect4 | detect3 | detect2 | detect1 | detect0;
	
	assign detect_out = all_zero & detect;
        
    
endmodule

