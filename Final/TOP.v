`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/12/19 15:52:17
// Design Name: 
// Module Name: TOP
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

`define IDLE 3'b000
`define player_A 3'b001
`define player_B 3'b010
`define DEALT 3'b011
`define SHOW 3'b100
module TOP(
    input clk,
    input rst,
    input start,
    input cancel,
    input get_win,
    input look_A,
    input look_B,
    inout PS2_CLK,
    inout PS2_DATA,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
);
    //compute money
        reg [7:0] A_money,A_money_next,B_money,B_money_next,pot,A_post,B_post,A_post_next,B_post_next,pot_next;
        reg [7:0] lastA_money,lastB_money,lastA_money_next,lastB_money_next;
        reg [7:0] num,num_next;
        reg OK,OK_next;
        reg all_inA,all_inA_next,all_inB,all_inB_next,allin_check,allin_check_next;
        wire [7:0] pot_divide_2,A_post_mul_2,B_post_mul_2;
        reg [3:0] now;
        reg [7:0] ans,input_1,input_2,input_3,input_4;
        reg [7:0] input_num0,input_num1,input_num2,input_num3,input_num4,input_num5,input_num6,input_num7,input_num8,input_num9;
        reg [7:0] input_num0_next,input_num1_next,input_num2_next,input_num3_next,input_num4_next,input_num5_next,input_num6_next,input_num7_next,input_num8_next,input_num9_next;
        assign pot_divide_2 = pot >> 1;
        assign A_post_mul_2 = A_post << 1;
        assign B_post_mul_2 = B_post << 1;


    //decide winner
    wire [5:0]win;
    wire valid0;
   // reg get_win,get_win_next;
    //VGA
    wire [11:0] data,data0;
    wire clk_25MHz;
    wire clk_22;
    wire [16:0] pixel_addr,pixel_addr0,pixel_addrL,pixel_addrR,pixel_addrM;
    wire [11:0] pixel,pixel0;
    wire [11:0] dataA,data2,data3,data4,data5,data6,data7,data8,data9,data10,dataJ,dataQ,dataK;
    wire [11:0] pixelA,pixel2,pixel3,pixel4,pixel5,pixel6,pixel7,pixel8,pixel9,pixel10,pixelJ,pixelQ,pixelK;
    wire [11:0] dataS,dataH,dataD,dataC;
    wire [11:0] pixelS,pixelH,pixelD,pixelC;
    wire [11:0] dataL,dataR,pixelL,pixelR,dataW,pixelW,data_coin,pixel_coin,data_money,pixel_money,data_dealer,pixel_dealer;
    wire [11:0] data_m0,data_m1,data_m2,data_m3,data_m4,data_m5,data_m6,data_m7,data_m8,data_m9;
    wire [11:0] pixel_m0,pixel_m1,pixel_m2,pixel_m3,pixel_m4,pixel_m5,pixel_m6,pixel_m7,pixel_m8,pixel_m9;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    wire [11:0] VGA_card0,VGA_card1,VGA_card2,VGA_card3,VGA_card4,VGA_card5,VGA_card6,VGA_card7,VGA_card8;
    

    //get cards
    wire [5:0] random;
    wire [5:0] out_card [0:8]; //陣列代表手牌的順序:AABB12345
    
    //card_to_pixel
    wire[11:0] pixel_n0,pixel_n1,pixel_n2,pixel_n3,pixel_n4,pixel_n5,pixel_n6,pixel_n7,pixel_n8;
    wire[11:0] pixel_c0,pixel_c1,pixel_c2,pixel_c3,pixel_c4,pixel_c5,pixel_c6,pixel_c7,pixel_c8;
    
    //money_to_pixel
    wire [11:0] out_num0,out_num1,out_num2,out_num3,out_num4,out_num5,out_num6,out_num7,out_num8,out_num9;
    
    //FSM
    wire clk13,clk25,clk16,clk10;
    reg turn,turn_next;
    reg done=1'b1,done_next;
    reg play,play_next; //遊戲中=1 還沒開始=0
    reg [2:0]deal,deal_next; //發公牌
    reg [2:0] give,give_next; // 發手牌
    reg [3:0] state,state_next;
    reg [5:0] A_hand[0:1],B_hand[0:1],card[0:4];    //每局重來時一定要全部歸零!!
    reg [5:0] A_hand_next[0:1],B_hand_next[0:1],card_next[0:4];
    
    //assign done=(state==`player_B)?1:0;
    /*assign A_hand[0]=6'b000001;
    assign A_hand[1]=6'b010001;
    assign B_hand[0]=6'b110001;
    assign B_hand[1]=6'b100001;
    assign card[0]=6'b110100;
    assign card[1]=6'b010100;
    assign card[2]=6'b110110;
    assign card[3]=6'b000010;
    assign card[4]=6'b000010;*/
    
    // keyboard
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;
    parameter [8:0] back = 9'b0_0110_0110;
    parameter [8:0] raise = 9'b0_0101_1010;//enter
    parameter [8:0] call = 9'b0_0010_0001;
    parameter [8:0] fold = 9'b0_0010_1011;
    parameter [8:0] KEY_CODES [0:19] = {
         9'b0_0100_0101,    // 0 => 45
         9'b0_0001_0110,    // 1 => 16
         9'b0_0001_1110,    // 2 => 1E
         9'b0_0010_0110,    // 3 => 26
         9'b0_0010_0101,    // 4 => 25
         9'b0_0010_1110,    // 5 => 2E
         9'b0_0011_0110,    // 6 => 36
         9'b0_0011_1101,    // 7 => 3D
         9'b0_0011_1110,    // 8 => 3E
         9'b0_0100_0110,    // 9 => 46
         
         9'b0_0111_0000, // right_0 => 70
         9'b0_0110_1001, // right_1 => 69
         9'b0_0111_0010, // right_2 => 72
         9'b0_0111_1010, // right_3 => 7A
         9'b0_0110_1011, // right_4 => 6B
         9'b0_0111_0011, // right_5 => 73
         9'b0_0111_0100, // right_6 => 74
         9'b0_0110_1100, // right_7 => 6C
         9'b0_0111_0101, // right_8 => 75
         9'b0_0111_1101  // right_9 => 7D
     };
    wire back_de,back_1pulse,raise_de,raise_1pulse,fold_de,fold_1pulse,call_de,call_1pulse;
    wire zero_de,zero_1pulse,one_de,one_1pulse,two_de,two_1pulse,three_de,three_1pulse,four_de,four_1pulse;
    wire five_de,five_1pulse,six_de,six_1pulse,seven_de,seven_1pulse,eight_de,eight_1pulse,nine_de,nine_1pulse;
    
    assign back_de=key_down[back];
    assign call_de=key_down[call];
    assign fold_de=key_down[fold];
    assign raise_de=key_down[raise];
    assign zero_de=key_down[KEY_CODES[0]]|key_down[KEY_CODES[10]];
    assign one_de=key_down[KEY_CODES[1]]|key_down[KEY_CODES[11]];
    assign two_de=key_down[KEY_CODES[2]]|key_down[KEY_CODES[12]];
    assign three_de=key_down[KEY_CODES[3]]|key_down[KEY_CODES[13]];
    assign four_de=key_down[KEY_CODES[4]]|key_down[KEY_CODES[14]];
    assign five_de=key_down[KEY_CODES[5]]|key_down[KEY_CODES[15]];
    assign six_de=key_down[KEY_CODES[6]]|key_down[KEY_CODES[16]];
    assign seven_de=key_down[KEY_CODES[7]]|key_down[KEY_CODES[17]];
    assign eight_de=key_down[KEY_CODES[8]]|key_down[KEY_CODES[18]];
    assign nine_de=key_down[KEY_CODES[9]]|key_down[KEY_CODES[19]];
    
    clock_divider #(.n(13)) c1(.clk(clk), .clk_div(clk13));
    clock_divider #(.n(25)) c2(.clk(clk), .clk_div(clk25));
    clock_divider #(.n(16)) c3(.clk(clk), .clk_div(clk16));
    clock_divider #(.n(12)) c4(.clk(clk), .clk_div(clk10));
    
    OnePulse Nb(.signal_single_pulse(back_1pulse),.signal(back_de),.clock(clk16));
    OnePulse Nc(.signal_single_pulse(call_1pulse),.signal(call_de),.clock(clk16));
    OnePulse Nf(.signal_single_pulse(fold_1pulse),.signal(fold_de),.clock(clk16));
    OnePulse Nr(.signal_single_pulse(raise_1pulse),.signal(raise_de),.clock(clk16));
    OnePulse N0(.signal_single_pulse(zero_1pulse),.signal(zero_de),.clock(clk16));
    OnePulse N1(.signal_single_pulse(one_1pulse),.signal(one_de),.clock(clk16));
    OnePulse N2(.signal_single_pulse(two_1pulse),.signal(two_de),.clock(clk16)); 
    OnePulse N3(.signal_single_pulse(three_1pulse),.signal(three_de),.clock(clk16));
    OnePulse N4(.signal_single_pulse(four_1pulse),.signal(four_de),.clock(clk16));
    OnePulse N5(.signal_single_pulse(five_1pulse),.signal(five_de),.clock(clk16));
    OnePulse N6(.signal_single_pulse(six_1pulse),.signal(six_de),.clock(clk16));
    OnePulse N7(.signal_single_pulse(seven_1pulse),.signal(seven_de),.clock(clk16));
    OnePulse N8(.signal_single_pulse(eight_1pulse),.signal(eight_de),.clock(clk16));
    OnePulse N9(.signal_single_pulse(nine_1pulse),.signal(nine_de),.clock(clk16));
    
    CompareCard G(.A_hand0(A_hand[0]),.A_hand1(A_hand[1]),.B_hand0(B_hand[0]),.B_hand1(B_hand[1]),.card0(card[0]),
        .card1(card[1]),.card2(card[2]),.card3(card[3]),.card4(card[4]),.out_card0(out_card[0]),.out_card1(out_card[1]),
        .out_card2(out_card[2]),.out_card3(out_card[3]),.out_card4(out_card[4]),.out_card5(out_card[5]),
        .out_card6(out_card[6]),.out_card7(out_card[7]),.out_card8(out_card[8]),.clk(clk),.rst(rst),.cancel(cancel),.play(play),
        .fold_1pulse(fold_1pulse),.give(give),.deal(deal));
     
     //num to pixel
     num_to_pixel ntp0(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[0][3:0]),.pixel(pixel_n0));

     num_to_pixel ntp1(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[1][3:0]),.pixel(pixel_n1));

     num_to_pixel ntp2(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[2][3:0]),.pixel(pixel_n2));

     num_to_pixel ntp3(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[3][3:0]),.pixel(pixel_n3));

     num_to_pixel ntp4(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[4][3:0]),.pixel(pixel_n4));

     num_to_pixel ntp5(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[5][3:0]),.pixel(pixel_n5));

     num_to_pixel ntp6(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[6][3:0]),.pixel(pixel_n6));

     num_to_pixel ntp7(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[7][3:0]),.pixel(pixel_n7));

     num_to_pixel ntp8(.pixelA(pixelA),.pixel2(pixel2),.pixel3(pixel3),.pixel4(pixel4),.pixel5(pixel5),.pixel6(pixel6),
                .pixel7(pixel7),.pixel8(pixel8),.pixel9(pixel9),.pixel10(pixel10),.pixelJ(pixelJ),.pixelQ(pixelQ),
                .pixelK(pixelK),.pixel0(pixel0),.num(out_card[8][3:0]),.pixel(pixel_n8));
    
    //color to pixel
    color_to_pixel ctp0(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[0]),.pixel(pixel_c0));
    color_to_pixel ctp1(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[1]),.pixel(pixel_c1));
    color_to_pixel ctp2(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[2]),.pixel(pixel_c2));
    color_to_pixel ctp3(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[3]),.pixel(pixel_c3));
    color_to_pixel ctp4(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[4]),.pixel(pixel_c4));
    color_to_pixel ctp5(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[5]),.pixel(pixel_c5));
    color_to_pixel ctp6(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[6]),.pixel(pixel_c6));
    color_to_pixel ctp7(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[7]),.pixel(pixel_c7));
    color_to_pixel ctp8(.pixelS(pixelS),.pixelH(pixelH),.pixelD(pixelD),.pixelC(pixelC),.pixel0(pixel0),.color(out_card[8]),.pixel(pixel_c8));
 
    //mouney_to_pixel
     money_to_pixel mtp0(.in_num(input_num0),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
    .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
    .pixel_m9(pixel_m9),.out_pixel(out_num0));

     money_to_pixel mtp1(.in_num(input_num1),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num1));

     money_to_pixel mtp2(.in_num(input_num2),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num2));

     money_to_pixel mtp3(.in_num(input_num3),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num3));

     money_to_pixel mtp4(.in_num(input_num4),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num4));

     money_to_pixel mtp5(.in_num(input_num5),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num5));

     money_to_pixel mtp6(.in_num(input_num6),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num6));
     
     money_to_pixel mtp7(.in_num(input_num7),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num7));
 
     money_to_pixel mtp8(.in_num(input_num8),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num8));
     
     money_to_pixel mtp9(.in_num(input_num9),.pixel_m0(pixel_m0),.pixel_m1(pixel_m1),.pixel_m2(pixel_m2),.pixel_m3(pixel_m3),
     .pixel_m4(pixel_m4),.pixel_m5(pixel_m5),.pixel_m6(pixel_m6),.pixel_m7(pixel_m7),.pixel_m8(pixel_m8),
     .pixel_m9(pixel_m9),.out_pixel(out_num9));
    
     KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );
    
    //decide winner
     decide_hand  DH(.clk(clk),.rst(get_win),.hand_a1(out_card[0]),.hand_a2(out_card[1]),.hand_b1(out_card[2]),.hand_b2(out_card[3])
        ,.hand_p1(out_card[4]),.hand_p2(out_card[5]),.hand_p3(out_card[6]),.hand_p4(out_card[7]),.hand_p5(out_card[8]),.win(win),.valid(valid0));
    
    //button
    wire start_de,start_1pulse;
    wire rst_de,rst_1pulse;
    wire cancel_de,cancel_1pulse;
    wire get_win_de,get_win_1pulse;
    debounce d1(.pb_debounced(rst_de),.pb(rst),.clk(clk16));
    debounce d2(.pb_debounced(start_de),.pb(start),.clk(clk16));
    debounce d3(.pb_debounced(cancel_de),.pb(cancel),.clk(clk16));
    debounce d4(.pb_debounced(get_win_de),.pb(get_win),.clk(clk16));
    OnePulse Or(.signal_single_pulse(rst_1pulse),.signal(rst_de),.clock(clk16));
    OnePulse Os(.signal_single_pulse(start_1pulse),.signal(start_de),.clock(clk16));
    OnePulse Oc(.signal_single_pulse(cancel_1pulse),.signal(cancel_de),.clock(clk16));
    OnePulse Og(.signal_single_pulse(get_win_1pulse),.signal(get_win_de),.clock(clk16));
    
      assign VGA_card0=(look_A)?pixel_n0:pixel0;
      assign VGA_card1=(look_A)?pixel_c0:pixel0;
      assign VGA_card2=(look_A)?pixel_n1:pixel0;
      assign VGA_card3=(look_A)?pixel_c1:pixel0;
      assign VGA_card4=(look_B)?pixel_n2:pixel0;
      assign VGA_card5=(look_B)?pixel_c2:pixel0;
      assign VGA_card6=(look_B)?pixel_n3:pixel0;
      assign VGA_card7=(look_B)?pixel_c3:pixel0;
      assign VGA_card8=pixel0;
        
    assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b0) ? 12'h0:
    ((h_cnt>>1)>0&& (h_cnt>>1)<=50 &&(v_cnt>>1)>15 && (v_cnt>>1)<=45 && state==`player_A && pixelL==12'h0)?pixelL:
    ((h_cnt>>1)>270&& (h_cnt>>1)<=320 &&(v_cnt>>1)>15 && (v_cnt>>1)<=45 && state==`player_B && pixelR==12'h0)?pixelR:
    ((h_cnt>>1)>0&& (h_cnt>>1)<=50 &&(v_cnt>>1)>15 && (v_cnt>>1)<=45 && state==`SHOW && pixelW!=12'b111111111111 && win[1:0]!=2'b01 && valid0)?pixelW:
    ((h_cnt>>1)>270&& (h_cnt>>1)<=320 &&(v_cnt>>1)>15 && (v_cnt>>1)<=45 && state==`SHOW && pixelW!=12'b111111111111 && win[1:0]!=2'b10 && valid0)?pixelW:
    ((h_cnt>>1)>15 && (h_cnt>>1)<=35 && (v_cnt>>1)>220 && (v_cnt>>1)<=240 && turn==0 &&pixel_dealer!=12'h0)?pixel_dealer:
    ((h_cnt>>1)>275 && (h_cnt>>1)<=295 && (v_cnt>>1)>220 && (v_cnt>>1)<=240 && turn==1 &&pixel_dealer!=12'h0)?pixel_dealer:
    ((h_cnt>>1)>50 && (h_cnt>>1)<=65 && (v_cnt>>1)>160 && (v_cnt>>1)<=185 && pixel_money!=12'h0)?pixel_money:
    ((h_cnt>>1)>210 && (h_cnt>>1)<=225 && (v_cnt>>1)>160 && (v_cnt>>1)<=185 && pixel_money!=12'h0)?pixel_money:
    ((h_cnt>>1)>60 && (h_cnt>>1)<=85 && (v_cnt>>1)>63 && (v_cnt>>1)<=83 && pixel_coin!=12'h0)?pixel_coin:
    ((h_cnt>>1)>195 && (h_cnt>>1)<=220 && (v_cnt>>1)>63 && (v_cnt>>1)<=83 && pixel_coin!=12'h0)?pixel_coin:
    ((h_cnt>>1)>65 && (h_cnt>>1)<=75 && (v_cnt>>1)>170 && (v_cnt>>1)<=185 && out_num0!=12'h0)?out_num0:
    ((h_cnt>>1)>75 && (h_cnt>>1)<=85 && (v_cnt>>1)>170 && (v_cnt>>1)<=185 && out_num1!=12'h0)?out_num1:
    ((h_cnt>>1)>225 && (h_cnt>>1)<=235 && (v_cnt>>1)>170 && (v_cnt>>1)<=185 && out_num2!=12'h0)?out_num2:
    ((h_cnt>>1)>235 && (h_cnt>>1)<=245 && (v_cnt>>1)>170 && (v_cnt>>1)<=185 && out_num3!=12'h0)?out_num3:
    ((h_cnt>>1)>85 && (h_cnt>>1)<=95 && (v_cnt>>1)>68 && (v_cnt>>1)<=83 && out_num4!=12'h0)?out_num4:
    ((h_cnt>>1)>95 && (h_cnt>>1)<=105 && (v_cnt>>1)>68 && (v_cnt>>1)<=83 && out_num5!=12'h0)?out_num5:
    ((h_cnt>>1)>143 && (h_cnt>>1)<=153 && (v_cnt>>1)>53 && (v_cnt>>1)<=68 && out_num6!=12'h0)?out_num6:
    ((h_cnt>>1)>153 && (h_cnt>>1)<=163 && (v_cnt>>1)>53 && (v_cnt>>1)<=68 && out_num7!=12'h0)?out_num7:
    ((h_cnt>>1)>220 && (h_cnt>>1)<=230 && (v_cnt>>1)>68 && (v_cnt>>1)<=83 && out_num8!=12'h0)?out_num8:
    ((h_cnt>>1)>230 && (h_cnt>>1)<=240 && (v_cnt>>1)>68 && (v_cnt>>1)<=83 && out_num9!=12'h0)?out_num9:
    ((h_cnt>>1)>41 && (h_cnt>>1)<=55 &&(v_cnt>>1)>190 && (v_cnt>>1)<=215 && VGA_card0!=12'h0)?VGA_card0:
    ((h_cnt>>1)>41 && (h_cnt>>1)<=70 &&(v_cnt>>1)>190 && (v_cnt>>1)<=240)?VGA_card1:
    ((h_cnt>>1)>81 && (h_cnt>>1)<=95 &&(v_cnt>>1)>190 && (v_cnt>>1)<=215 && VGA_card2!=12'h0)?VGA_card2:
    ((h_cnt>>1)>81 && (h_cnt>>1)<=110 &&(v_cnt>>1)>190 && (v_cnt>>1)<=240)?VGA_card3:
    ((h_cnt>>1)>201 && (h_cnt>>1)<=215 &&(v_cnt>>1)>190 && (v_cnt>>1)<=215 && VGA_card4!=12'h0)?VGA_card4:
    ((h_cnt>>1)>201 && (h_cnt>>1)<=230 &&(v_cnt>>1)>190 && (v_cnt>>1)<=240)?VGA_card5:
    ((h_cnt>>1)>241 && (h_cnt>>1)<=255 &&(v_cnt>>1)>190 && (v_cnt>>1)<=215 && VGA_card6!=12'h0)?VGA_card6:
    ((h_cnt>>1)>241 && (h_cnt>>1)<=270 &&(v_cnt>>1)>190 && (v_cnt>>1)<=240)?VGA_card7:
    ((h_cnt>>1)>49 && (h_cnt>>1)<=63 &&(v_cnt>>1)>88 && (v_cnt>>1)<=113 && pixel_n4!=12'h0)?pixel_n4:
    ((h_cnt>>1)>49 && (h_cnt>>1)<=78 &&(v_cnt>>1)>88 && (v_cnt>>1)<=138)?pixel_c4:
    ((h_cnt>>1)>94 && (h_cnt>>1)<=108 &&(v_cnt>>1)>88 && (v_cnt>>1)<=113 && pixel_n5!=12'h0)?pixel_n5:
    ((h_cnt>>1)>94 && (h_cnt>>1)<=123 &&(v_cnt>>1)>88 && (v_cnt>>1)<=138)?pixel_c5:
    ((h_cnt>>1)>139 && (h_cnt>>1)<=153 &&(v_cnt>>1)>88 && (v_cnt>>1)<=113 && pixel_n6!=12'h0)?pixel_n6:
    ((h_cnt>>1)>139 && (h_cnt>>1)<=168 &&(v_cnt>>1)>88 && (v_cnt>>1)<=138)?pixel_c6:
    ((h_cnt>>1)>184 && (h_cnt>>1)<=198 &&(v_cnt>>1)>88 && (v_cnt>>1)<=113 && pixel_n7!=12'h0)?pixel_n7:
    ((h_cnt>>1)>184 && (h_cnt>>1)<=213 &&(v_cnt>>1)>88 && (v_cnt>>1)<=138)?pixel_c7:
    ((h_cnt>>1)>229 && (h_cnt>>1)<=243 &&(v_cnt>>1)>88 && (v_cnt>>1)<=113 && pixel_n8!=12'h0)?pixel_n8:
    ((h_cnt>>1)>229 && (h_cnt>>1)<=258 &&(v_cnt>>1)>88 && (v_cnt>>1)<=138)?pixel_c8:pixel;
    
         clock_divisor clk_wiz_0_inst(
          .clk(clk),
          .clk1(clk_25MHz),
          .clk22(clk_22)
        );
    
        mem_addr_gen mem_addr_gen_inst(
        .clk(clk_22),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr),
        .pixel_addrR(pixel_addrR)
        );
        
        card_to_show show(
        .clk(clk_22),
        .rst(rst),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr0),
        .pixel_addrM(pixel_addrM)
        );
        
          
        blk_mem_gen_0 blk_mem_gen_0_inst(
          .clka(clk_25MHz),
          .wea(0),
          .addra(pixel_addr),
          .dina(data[11:0]),
          .douta(pixel)
        ); 
        
    
        vga_controller   vga_inst(
          .pclk(clk_25MHz),
          .reset(rst),
          .hsync(hsync),
          .vsync(vsync),
          .valid(valid),
          .h_cnt(h_cnt),
          .v_cnt(v_cnt)
        );
        
        back_pic back_pic(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data0[11:0]),.douta(pixel0)); 
        
        //number
        pic_A pic_A(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataA[11:0]),.douta(pixelA));
        pic_2 pic_2(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data2[11:0]),.douta(pixel2)); 
        pic_3 pic_3(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data3[11:0]),.douta(pixel3)); 
        pic_4 pic_4(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data4[11:0]),.douta(pixel4)); 
        pic_5 pic_5(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data5[11:0]),.douta(pixel5)); 
        pic_6 pic_6(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data6[11:0]),.douta(pixel6)); 
        pic_7 pic_7(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data7[11:0]),.douta(pixel7)); 
        pic_8 pic_8(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data8[11:0]),.douta(pixel8)); 
        pic_9 pic_9(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data9[11:0]),.douta(pixel9)); 
        pic_10 pic_10(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(data10[11:0]),.douta(pixel10)); 
        pic_J pic_J(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataJ[11:0]),.douta(pixelJ)); 
        pic_Q pic_Q(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataQ[11:0]),.douta(pixelQ)); 
        pic_K pic_K(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataK[11:0]),.douta(pixelK));  
        
        //color
         pic_S pic_S(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataS[11:0]),.douta(pixelS));
         pic_H pic_H(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataH[11:0]),.douta(pixelH));
         pic_D pic_D(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataD[11:0]),.douta(pixelD));
         pic_C pic_C(.clka(clk_25MHz),.wea(0),.addra(pixel_addr0),.dina(dataC[11:0]),.douta(pixelC));
         
         //turn
         L_turn L_turn(.clka(clk_25MHz),.wea(0),.addra(pixel_addrR),.dina(dataL[11:0]),.douta(pixelL));
         R_turn R_turn(.clka(clk_25MHz),.wea(0),.addra(pixel_addrR),.dina(dataR[11:0]),.douta(pixelR));  
         win_pic win_pic(.clka(clk_25MHz),.wea(0),.addra(pixel_addrR),.dina(dataW[11:0]),.douta(pixelW));  
         
         //token
         money_pic money_pic(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_coin[11:0]),.douta(pixel_money));
         coin_pic coin_pic(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_coin[11:0]),.douta(pixel_coin));
         dealer_pic dealer_pic(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_dealer[11:0]),.douta(pixel_dealer));
         
         //money_num
        num_0 num_0(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m0[11:0]),.douta(pixel_m0));
        num_1 num_1(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m1[11:0]),.douta(pixel_m1));
        num_2 num_2(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m2[11:0]),.douta(pixel_m2));
        num_3 num_3(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m3[11:0]),.douta(pixel_m3));
        num_4 num_4(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m4[11:0]),.douta(pixel_m4));
        num_5 num_5(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m5[11:0]),.douta(pixel_m5));
        num_6 num_6(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m6[11:0]),.douta(pixel_m6));
        num_7 num_7(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m7[11:0]),.douta(pixel_m7));
        num_8 num_8(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m8[11:0]),.douta(pixel_m8));
        num_9 num_9(.clka(clk_25MHz),.wea(0),.addra(pixel_addrM),.dina(data_m9[11:0]),.douta(pixel_m9));
        
        //getcard
        GetCard r(.random(random),.clk(clk16));
        


    always@(*)begin
        case(state)
            `IDLE:begin
                if(start_1pulse)begin
                    if(give<3'd3)begin
                        state_next<=`IDLE;
                    end
                    else begin
                        if(turn==0)begin
                            state_next<=`player_A; // turn == 0 -> A的回合 
                        end
                        else begin
                            state_next<=`player_B; // turn == 1 -> B的回合 
                        end
                    end
                end
                else begin
                    state_next<=`IDLE;
                end
            end
            `player_A:begin
                if(rst_1pulse||fold_1pulse||cancel_1pulse)begin 
                    state_next<=`IDLE;
                end
                else if(call_1pulse)begin
                    if(done==1)begin
                        state_next<=`DEALT;
                    end
                    else begin
                        state_next<=`player_B;
                    end
                end
                else if(raise_1pulse)begin
					if(num < A_post_mul_2)
						state_next<=`player_A;
					else
						state_next<=`player_B;  //這一段必須判斷是否符合raise標準，所以code未完成！！
                end
                else begin
                    state_next<=`player_A;
                end
            end
            `player_B:begin
                if(rst_1pulse||cancel_1pulse||fold_1pulse)begin
                    state_next<=`IDLE;
                end
                else if(call_1pulse)begin
                    if(done==1)begin
                        state_next<=`DEALT;
                    end
                    else begin
                        state_next<=`player_A;
                    end
                end
                else if(raise_1pulse)begin
					if(num < B_post_mul_2)
						state_next<=`player_B;
					else
						state_next<=`player_A;  //這一段必須判斷是否符合raise標準，所以code未完成！！
                end
                else begin
                    state_next<=`player_B;
                end
            end
            `DEALT:begin
                if(cancel_1pulse||rst_1pulse)begin
                    state_next<=`IDLE;
                end
                else if(start_1pulse)begin
                    if(allin_check)begin
                        state_next<=`DEALT;
                    end
                    else begin
                        if(deal<3'd2)begin
                            state_next<=`DEALT;
                        end
                        else if(deal>=3'd2 && deal<3'd5)begin
                            if(turn==0)begin           //turn=1 從A玩家先喊
                                state_next<=`player_B;
                            end
                            else begin
                                state_next<=`player_A;
                            end
                        end
                        else begin
                            state_next<=`DEALT; //!!
                        end
                    end
                end
                else if(get_win_1pulse)begin
                    state_next<=`SHOW;
                end
                else begin
                    state_next<=`DEALT;
                end
            end
            `SHOW:begin
                if(start_1pulse||rst_1pulse)begin
                    state_next<=`IDLE;
                end
                else begin
                    state_next<=`SHOW;
                end
            end
        endcase
    end
    
    //DFF
    always@(posedge clk16 or posedge rst or posedge cancel_1pulse)begin  //缺cancel&fold
        if(rst)begin
            state<=`IDLE;
            give<=0;
            deal<=0;
            A_hand[0]<=0;
            A_hand[1]<=0;
            B_hand[0]<=0;
            B_hand[1]<=0;
            card[0]<=0;
            card[1]<=0;
            card[2]<=0;
            card[3]<=0;
            card[4]<=0;
            turn<=0;
            play<=0;
            done<=1;

            OK = 1'b0; 
            allin_check = 1'b0;
            A_money = 8'd45;
            B_money = 8'd45;
            A_post= 8'd0;
            B_post = 8'd1;
            lastA_money = 8'd45;
            lastB_money = 8'd45;
            pot = 8'd0;
            all_inA <= 0;
            all_inB <= 0;
            allin_check <= 0;
            input_num0 <= 0;
            input_num1 <= 0;
            input_num2 <= 0;
            input_num3 <= 0;
            input_num4 <= 0;
            input_num5 <= 0;
            input_num6 <= 0;
            input_num7 <= 0;
            input_num8 <= 0;
            input_num9 <= 0;
        end
        else if(cancel_1pulse)begin
            state<=`IDLE;
            give<=0;
            deal<=0;
            A_hand[0]<=0;
            A_hand[1]<=0;
            B_hand[0]<=0;
            B_hand[1]<=0;
            card[0]<=0;
            card[1]<=0;
            card[2]<=0;
            card[3]<=0;
            card[4]<=0;
            turn<=turn_next;
            play<=0;
            done<=1;   

            OK = 1'b0;            
            allin_check = 1'b0;
            A_money = lastA_money;
            B_money = lastB_money;
            lastA_money = lastA_money;
            lastB_money = lastB_money;
            A_post =(turn==0)?8'd0:8'd1;
            B_post =(turn==0)?8'd1:8'd0;
            pot = 8'd0;
            all_inA <= 0;
            all_inB <= 0;
            allin_check <= 0;
            input_num0 <= 0;
            input_num1 <= 0;
            input_num2 <= 0;
            input_num3 <= 0;
            input_num4 <= 0;
            input_num5 <= 0;
            input_num6 <= 0;
            input_num7 <= 0;
            input_num8 <= 0;
            input_num9 <= 0;
        end
        else begin
            state<=state_next;
            give<=give_next;
            deal<=deal_next;
            A_hand[0]<=A_hand_next[0];
            A_hand[1]<=A_hand_next[1];
            B_hand[0]<=B_hand_next[0];
            B_hand[1]<=B_hand_next[1];
            card[0]<=card_next[0];
            card[1]<=card_next[1];
            card[2]<=card_next[2];
            card[3]<=card_next[3];
            card[4]<=card_next[4];
            turn<=turn_next;
            play<=play_next;
            done<=done_next;
            
	        A_money <= A_money_next;
            B_money <= B_money_next;
            A_post <= A_post_next;
            B_post <= B_post_next;
            lastA_money <= lastA_money_next;
            lastB_money <= lastB_money_next;
            num <= num_next;
            OK <= OK_next;
            pot <= pot_next;
            all_inA <= all_inA_next;
            all_inB <= all_inB_next;
            allin_check <= allin_check_next;
            input_num0 <= input_num0_next;
            input_num1 <= input_num1_next;
            input_num2 <= input_num2_next;
            input_num3 <= input_num3_next;
            input_num4 <= input_num4_next;
            input_num5 <= input_num5_next;
            input_num6 <= input_num6_next;
            input_num7 <= input_num7_next;
            input_num8 <= input_num8_next;
            input_num9 <= input_num9_next;
        end
    end
    
    //FSM
    always@(*)begin
        case(state)
            `IDLE:begin
                turn_next=turn;
                done_next=done;
                play_next=play;
                if(start_1pulse)begin
                    play_next<=1'b1;
                end
            end
            `player_A:begin
                turn_next=turn;
                play_next=play;
                done_next=done;
                if(call_1pulse||raise_1pulse)begin
                    done_next=1;
                end
                if(fold_1pulse)begin
                    done_next=0;
                    play_next=0;
					turn_next = ~turn;
                end
            end
            `player_B:begin
                turn_next = turn;
                play_next=play;
                done_next=done;
                if(call_1pulse||raise_1pulse)begin
                    done_next=1;
                end
                if(fold_1pulse)begin
                    done_next=0;
                    play_next=0;
					turn_next = ~turn;
                end
            end
            `DEALT:begin
                turn_next=turn;
                play_next=play;
                done_next=0;
            end
            `SHOW:begin
                turn_next=turn;
                play_next=play;
                done_next=done;
                if(start_1pulse)begin
                    turn_next=~turn;
                    done_next=1;
                    play_next=0;
                end
            end
        endcase
    end

// get_card
    always@(*)begin
        case(state)
            `IDLE:begin
                A_hand_next[0]=A_hand[0];
                A_hand_next[1]=A_hand[1];
                B_hand_next[0]=B_hand[0];
                B_hand_next[1]=B_hand[1];
                card_next[0]=card[0];
                card_next[1]=card[1];
                card_next[2]=card[2];
                card_next[3]=card[3];
                card_next[4]=card[4];
                give_next=give;
                deal_next=deal;
                if(start_1pulse)begin
                    if(give==3'd0)begin
                        give_next=3'd1;
                        A_hand_next[0]=random;
                    end
                    else if(give==3'd1)begin
                        give_next=3'd2;
                        A_hand_next[1]=random;
                    end
                    else if(give==3'd2)begin
                        give_next=3'd3;
                        B_hand_next[0]=random;
                    end
                    else if(give==3'd3)begin
                        give_next=3'd4;
                        B_hand_next[1]=random;
                    end                    
                end
            end
            `player_A:begin
                A_hand_next[0]=A_hand[0];
                A_hand_next[1]=A_hand[1];
                B_hand_next[0]=B_hand[0];
                B_hand_next[1]=B_hand[1];
                card_next[0]=card[0];
                card_next[1]=card[1];
                card_next[2]=card[2];
                card_next[3]=card[3];
                card_next[4]=card[4];
                give_next=give;
                deal_next=deal;
                if(fold_1pulse)begin
                    A_hand_next[0]=0;
                    A_hand_next[1]=0;
                    B_hand_next[0]=0;
                    B_hand_next[1]=0;
                    card_next[0]=0;
                    card_next[1]=0;
                    card_next[2]=0;
                    card_next[3]=0;
                    card_next[4]=0;
                    give_next=0;
                    deal_next=0; 
                end
            end
            `player_B:begin
                A_hand_next[0]=A_hand[0];
                A_hand_next[1]=A_hand[1];
                B_hand_next[0]=B_hand[0];
                B_hand_next[1]=B_hand[1];
                card_next[0]=card[0];
                card_next[1]=card[1];
                card_next[2]=card[2];
                card_next[3]=card[3];
                card_next[4]=card[4];
                give_next=give;
                deal_next=deal;
                if(fold_1pulse)begin
                    A_hand_next[0]=0;
                    A_hand_next[1]=0;
                    B_hand_next[0]=0;
                    B_hand_next[1]=0;
                    card_next[0]=0;
                    card_next[1]=0;
                    card_next[2]=0;
                    card_next[3]=0;
                    card_next[4]=0;
                    give_next=0;
                    deal_next=0; 
                end
            end
            `DEALT:begin
                A_hand_next[0]=A_hand[0];
                A_hand_next[1]=A_hand[1];
                B_hand_next[0]=B_hand[0];
                B_hand_next[1]=B_hand[1];
                card_next[0]=card[0];
                card_next[1]=card[1];
                card_next[2]=card[2];
                card_next[3]=card[3];
                card_next[4]=card[4];
                give_next=give;
                deal_next=deal;
                if(start_1pulse)begin
                    if(deal==3'd0)begin
                        deal_next=3'd1;
                        card_next[0]=random;
                    end
                    else if(deal==3'd1)begin
                        deal_next=3'd2;
                        card_next[1]=random;
                    end
                    else if(deal==3'd2)begin
                        deal_next=3'd3;
                        card_next[2]=random;
                    end
                    else if(deal==3'd3)begin
                        deal_next=3'd4;
                        card_next[3]=random;
                    end
                    else if(deal==3'd4)begin
                        deal_next=3'd5;
                        card_next[4]=random;
                    end
                end
            end
            `SHOW:begin
                A_hand_next[0]=A_hand[0];
                A_hand_next[1]=A_hand[1];
                B_hand_next[0]=B_hand[0];
                B_hand_next[1]=B_hand[1];
                card_next[0]=card[0];
                card_next[1]=card[1];
                card_next[2]=card[2];
                card_next[3]=card[3];
                card_next[4]=card[4];
                give_next=give;
                deal_next=deal;
                if(start_1pulse)begin
                    A_hand_next[0]=0;
                    A_hand_next[1]=0;
                    B_hand_next[0]=0;
                    B_hand_next[1]=0;
                    card_next[0]=0;
                    card_next[1]=0;
                    card_next[2]=0;
                    card_next[3]=0;
                    card_next[4]=0;
                    give_next=0;
                    deal_next=0; 
                end
            end
            default:begin
                A_hand_next[0]=A_hand[0];
                A_hand_next[1]=A_hand[1];
                B_hand_next[0]=B_hand[0];
                B_hand_next[1]=B_hand[1];
                card_next[0]=card[0];
                card_next[1]=card[1];
                card_next[2]=card[2];
                card_next[3]=card[3];
                card_next[4]=card[4];
                give_next=give;
                deal_next=deal;
            end
        endcase
    end
    //compute money
	always@(*) begin
        case(state)
            `IDLE:begin
                OK_next = 1'b0;
                allin_check_next = 1'b0;
                A_money_next = A_money;
                B_money_next = B_money;
                A_post_next = A_post;
                B_post_next = B_post;
                lastA_money_next = lastA_money;
                lastB_money_next = lastB_money;
                pot_next = 8'd0;
            end
            `player_A:begin
                OK_next = 1'b0;
                if(fold_1pulse) begin
                    allin_check_next = 1'b0;
                    pot_next = 8'd0;
                    A_money_next = A_money - A_post;
                    B_money_next = B_money + A_post + pot;
                    lastA_money_next = A_money - A_post;
                    lastB_money_next = B_money + A_post + pot;
                    if(turn == 0) begin
                        A_post_next = 8'd0;
                        B_post_next = 8'd1;
                    end
                    else begin
                        A_post_next = 8'd1;
                        B_post_next = 8'd0;    
                    end
                end
                else if(call_1pulse) begin
                    if(all_inB == 1'b1) begin
                        allin_check_next = 1'b1;
                        if(B_post > A_money) begin
                            A_money_next = 8'd0;
                            B_money_next = B_money - A_money;
                            A_post_next = A_money;
                            B_post_next = A_money;
                            lastA_money_next = lastA_money;
                            lastB_money_next = lastB_money;
                            pot_next = A_money << 1;
                        end
                        else begin
                            A_money_next = A_money - B_money;
                            B_money_next = 8'd0;
                            A_post_next = B_money;
                            B_post_next = B_money;
                            lastA_money_next = lastA_money;
                            lastB_money_next = lastB_money;
                            pot_next = B_money << 1;
                        end
                    end
                    else if(done == 1'b1) begin
                        allin_check_next = 1'b0;
                        A_money_next = A_money - B_post;
                        B_money_next = B_money - B_post;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = B_post;
                        B_post_next = B_post;
                        pot_next = pot + (B_post << 1);
                    end
                    else begin
                        allin_check_next = 1'b0;
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = 8'd0;
                        B_post_next = 8'd0;
                        pot_next = pot;
                    end
                end
                else if(raise_1pulse) begin
                    allin_check_next = 1'b0;
                    pot_next = pot;
                    if(all_inA == 1'b1) begin
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = A_money;
                        B_post_next = B_post;
                    end
                    else if(num < B_post_mul_2) begin
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = A_post;
                        B_post_next = B_post;
                    end
                    else begin
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = num;
                        B_post_next = B_post;
                    end
                end
				else begin
                    A_money_next = A_money;
                    B_money_next = B_money;
                    lastA_money_next = lastA_money;
                    lastB_money_next = lastB_money;
                    A_post_next = A_post;
                    B_post_next = B_post;
				end
            end
            `player_B : begin
                OK_next = 1'b0;
                if(fold_1pulse) begin
                    allin_check_next = 1'b0;
                    A_money_next = A_money + B_post + pot;
                    B_money_next = B_money - B_post;
                    lastA_money_next = A_money + B_post + pot;
                    lastB_money_next = B_money - B_post;
                    pot_next = 8'd0;
                    if(turn == 0) begin
                        A_post_next = 8'd0;
                        B_post_next = 8'd1;
                    end
                    else begin
                        A_post_next = 8'd1;
                        B_post_next = 8'd0;    
                    end
                end
                else if(call_1pulse) begin
                    if(all_inA == 1'b1) begin
                        allin_check_next = 1'b1;
                        if(A_post > B_money) begin
                            A_money_next = A_money - B_money;
                            B_money_next = 8'd0;
                            A_post_next = B_money;
                            B_post_next = B_money;
                            lastA_money_next = lastA_money;
                            lastB_money_next = lastB_money;
                            pot_next = B_money << 1;
                        end
                        else begin
                            A_money_next = 8'd0;
                            B_money_next = B_money - A_money;
                            A_post_next = A_money;
                            B_post_next = A_money;
                            lastA_money_next = lastA_money;
                            lastB_money_next = lastB_money;
                            pot_next = A_money << 1;
                        end
                    end
                    else if(done == 1'b1) begin
                        allin_check_next = 1'b0;
                        A_money_next = A_money - A_post;
                        B_money_next = B_money - A_post;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = A_post;
                        B_post_next = A_post;
                        pot_next = pot + (A_post << 1);
                    end
                    else begin
                        allin_check_next = 1'b0;
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = 8'd0;
                        B_post_next = 8'd0;
                        pot_next = pot;
                    end
                end
                else if(raise_1pulse) begin
                    allin_check_next = 1'b0;
                    pot_next = pot;
                    if(all_inB == 1'b1) begin
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = A_post;
                        B_post_next = B_money;
                    end
                    else if(num < A_post_mul_2) begin
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = A_post;
                        B_post_next = B_post;
                    end
                    else begin
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        A_post_next = A_post;
                        B_post_next = num;
                    end
                end
				else begin
                    A_money_next = A_money;
                    B_money_next = B_money;
                    lastA_money_next = lastA_money;
                    lastB_money_next = lastB_money;
                    A_post_next = A_post;
                    B_post_next = B_post;
				end
            end
            `DEALT : begin
                OK_next = 1'b0;
                allin_check_next = allin_check;
                A_money_next = A_money;
                B_money_next = B_money;
                lastA_money_next = lastA_money;
                lastB_money_next = lastB_money;
                A_post_next = 8'd0;
                B_post_next = 8'd0;    
                pot_next = pot;
            end
            `SHOW:begin
                allin_check_next = allin_check;
                if(valid0 == 1'b1) begin
                    if(OK == 1'b1) begin
                        OK_next = OK;
                        A_money_next = A_money;
                        B_money_next = B_money;
                        lastA_money_next = lastA_money;
                        lastB_money_next = lastB_money;
                        pot_next = 8'd0;
                    end
                    else if(win[1:0] == 2'b11) begin
                        OK_next = 1'b1;
                        A_money_next = A_money + pot_divide_2;
                        B_money_next = B_money + pot_divide_2;
                        lastA_money_next = A_money + pot_divide_2;
                        lastB_money_next = B_money + pot_divide_2;
                        pot_next = 8'd0;
                    end
                    else if(win[1:0] == 2'b10) begin
                        OK_next = 1'b1;
                        A_money_next = A_money + pot;
                        B_money_next = B_money;
                        lastA_money_next = A_money + pot;
                        lastB_money_next = B_money;
                        pot_next = 8'd0;
                    end
                    else if(win[1:0] == 2'b01) begin
                        OK_next = 1'b1;
                        A_money_next = A_money;
                        B_money_next = B_money + pot;
                        lastA_money_next = A_money;
                        lastB_money_next = B_money + pot;
                        pot_next = 8'd0;
                    end
                    else begin
                        OK_next = 1'b1;
                        A_money_next = A_money + pot_divide_2;
                        B_money_next = B_money + pot_divide_2;
                        lastA_money_next = A_money + pot_divide_2;
                        lastB_money_next = B_money + pot_divide_2;
                        pot_next = 8'd0;
                    end
                end
                else begin
                    OK_next = 1'b0;
                    A_money_next = A_money;
                    B_money_next = B_money;
                    lastA_money_next = lastA_money;
                    lastB_money_next = lastB_money;
                    pot_next = pot;
                end
            end
        endcase
    end
    always@(*) begin
        if(state == `player_A) begin
            all_inB_next = all_inB;
            if(raise_1pulse == 1'b1) begin
                if(num < B_post_mul_2 && all_inA != 1'b1)
                    num_next = 8'd91;
                else
                    num_next = num;
                all_inA_next = all_inA;
            end
            else if(num == 8'd91) begin
                num_next = 8'd0;
                all_inA_next = 1'b0;
            end
            else if(back_1pulse == 1'b1) begin
                num_next = 8'd0;
                all_inA_next = 1'b0;
            end
            else if(zero_1pulse == 1'b1 && (num < A_money - 8'd10 || num == A_money - 8'd10))begin
                num_next = num + 8'd10;
                all_inA_next = 1'b0;
            end
            else if(one_1pulse == 1'b1 && (num < A_money - 8'd1 || num == A_money - 8'd1))begin
                num_next = num + 8'd1;
                all_inA_next = 1'b0;
            end
            else if(five_1pulse == 1'b1 && (num < A_money - 8'd5 || num == A_money - 8'd5))begin
                num_next = num + 8'd5;
                all_inA_next = 1'b0;
            end
            else if(nine_1pulse == 1'b1) begin
                num_next = A_money;
                all_inA_next = 1'b1;
            end
            else begin
                num_next = num;
                all_inA_next = all_inA;
            end
        end
        else if(state == `player_B) begin
            all_inA_next = all_inA;
            if(raise_1pulse == 1'b1) begin
                if(num < A_post_mul_2 && all_inB != 1'b1)
                    num_next = 8'd91;
                else
                    num_next = num;
                all_inB_next = all_inB;
            end
            else if(num == 8'd91) begin
                num_next = 8'd0;
                all_inB_next = 1'b0;
            end
            else if(back_1pulse == 1'b1) begin
                num_next = 8'd0;
                all_inB_next = 1'b0;
            end
            else if(zero_1pulse == 1'b1 && (num < B_money - 8'd10 || num == B_money - 8'd10))begin
                num_next = num + 8'd10;
                all_inB_next = 1'b0;
            end
            else if(one_1pulse == 1'b1 && (num < B_money - 8'd1 || num == B_money - 8'd1))begin
                num_next = num + 8'd1;
                all_inB_next = 1'b0;
            end
            else if(five_1pulse == 1'b1 && (num < B_money - 8'd5 || num == B_money - 8'd5))begin
                num_next = num + 8'd5;
                all_inB_next = 1'b0;
            end
            else if(nine_1pulse == 1'b1) begin
                num_next = B_money;
                all_inB_next = 1'b1;
            end
            else begin
                num_next = num;
                all_inB_next = all_inB;
            end
        end
        else begin
            num_next = 8'd0;
            all_inA_next = all_inA;
            all_inB_next = all_inB;
        end
    end
    
    
    
    
    
    always@(*) begin
        if(A_money == 8'd90) begin
            input_num0_next = 8'd9;
            input_num1_next = 8'd0;
        end
        if(A_money > 8'd79) begin
            input_num0_next = 8'd8;
            input_num1_next = A_money - 8'd80;
        end
        else if(A_money > 8'd69) begin
            input_num0_next = 8'd7;
            input_num1_next = A_money - 8'd70;
        end
        else if(A_money > 8'd59) begin
            input_num0_next = 8'd6;
            input_num1_next = A_money - 8'd60;
        end
        else if(A_money > 8'd49) begin
            input_num0_next = 8'd5;
            input_num1_next = A_money - 8'd50;
        end
        else if(A_money > 8'd39) begin
            input_num0_next = 8'd4;
            input_num1_next = A_money - 8'd40;
        end
        else if(A_money > 8'd29) begin
            input_num0_next = 8'd3;
            input_num1_next = A_money - 8'd30;
        end
        else if(A_money > 8'd19) begin
            input_num0_next = 8'd2;
            input_num1_next = A_money - 8'd20;
        end    
        else if(A_money > 8'd9) begin
            input_num0_next = 8'd1;
            input_num1_next = A_money - 8'd10;
        end
        else begin
            input_num0_next = 8'd0;
            input_num1_next = A_money;
        end
    end
    always@(*) begin
        if(B_money == 8'd90) begin
            input_num2_next = 8'd9;
            input_num3_next = 8'd0;
        end
        if(B_money > 8'd79) begin
            input_num2_next = 8'd8;
            input_num3_next = B_money - 8'd80;
        end
        else if(B_money > 8'd69) begin
            input_num2_next = 8'd7;
            input_num3_next = B_money - 8'd70;
        end
        else if(B_money > 8'd59) begin
            input_num2_next = 8'd6;
            input_num3_next = B_money - 8'd60;
        end
        else if(B_money > 8'd49) begin
            input_num2_next = 8'd5;
            input_num3_next = B_money - 8'd50;
        end
        else if(B_money > 8'd39) begin
            input_num2_next = 8'd4;
            input_num3_next = B_money - 8'd40;
        end
        else if(B_money > 8'd29) begin
            input_num2_next = 8'd3;
            input_num3_next = B_money - 8'd30;
        end
        else if(B_money > 8'd19) begin
            input_num2_next = 8'd2;
            input_num3_next = B_money - 8'd20;
        end    
        else if(B_money > 8'd9) begin
            input_num2_next = 8'd1;
            input_num3_next = B_money - 8'd10;
        end
        else begin
            input_num2_next = 8'd0;
            input_num3_next = B_money;
        end
    end
    always@(*) begin
        if(A_post == 8'd90) begin
            input_num4_next = 8'd9;
            input_num5_next = 8'd0;
        end
        if(A_post > 8'd79) begin
            input_num4_next = 8'd8;
            input_num5_next = A_post - 8'd80;
        end
        else if(A_post > 8'd69) begin
            input_num4_next = 8'd7;
            input_num5_next = A_post - 8'd70;
        end
        else if(A_post > 8'd59) begin
            input_num4_next = 8'd6;
            input_num5_next = A_post - 8'd60;
        end
        else if(A_post > 8'd49) begin
            input_num4_next = 8'd5;
            input_num5_next = A_post - 8'd50;
        end
        else if(A_post > 8'd39) begin
            input_num4_next = 8'd4;
            input_num5_next = A_post - 8'd40;
        end
        else if(A_post > 8'd29) begin
            input_num4_next = 8'd3;
            input_num5_next = A_post - 8'd30;
        end
        else if(A_post > 8'd19) begin
            input_num4_next = 8'd2;
            input_num5_next = A_post - 8'd20;
        end    
        else if(A_post > 8'd9) begin
            input_num4_next = 8'd1;
            input_num5_next = A_post - 8'd10;
        end
        else begin
            input_num4_next = 8'd0;
            input_num5_next = A_post;
        end
    end
    always@(*) begin
        if(pot == 8'd90) begin
            input_num6_next = 8'd9;
            input_num7_next = 8'd0;
        end
        if(pot > 8'd79) begin
            input_num6_next = 8'd8;
            input_num7_next = pot - 8'd80;
        end
        else if(pot > 8'd69) begin
            input_num6_next = 8'd7;
            input_num7_next = pot - 8'd70;
        end
        else if(pot > 8'd59) begin
            input_num6_next = 8'd6;
            input_num7_next = pot - 8'd60;
        end
        else if(pot > 8'd49) begin
            input_num6_next = 8'd5;
            input_num7_next = pot - 8'd50;
        end
        else if(pot > 8'd39) begin
            input_num6_next = 8'd4;
            input_num7_next = pot - 8'd40;
        end
        else if(pot > 8'd29) begin
            input_num6_next = 8'd3;
            input_num7_next = pot - 8'd30;
        end
        else if(pot > 8'd19) begin
            input_num6_next = 8'd2;
            input_num7_next = pot - 8'd20;
        end    
        else if(pot > 8'd9) begin
            input_num6_next = 8'd1;
            input_num7_next = pot - 8'd10;
        end
        else begin
            input_num6_next = 8'd0;
            input_num7_next = pot;
        end
    end
    always@(*) begin
        if(B_post == 8'd90) begin
            input_num8_next = 8'd9;
            input_num9_next = 8'd0;
        end
        if(B_post > 8'd79) begin
            input_num8_next = 8'd8;
            input_num9_next = B_post - 8'd80;
        end
        else if(B_post > 8'd69) begin
            input_num8_next = 8'd7;
            input_num9_next = B_post - 8'd70;
        end
        else if(B_post > 8'd59) begin
            input_num8_next = 8'd6;
            input_num9_next = B_post - 8'd60;
        end
        else if(B_post > 8'd49) begin
            input_num8_next = 8'd5;
            input_num9_next = B_post - 8'd50;
        end
        else if(B_post > 8'd39) begin
            input_num8_next = 8'd4;
            input_num9_next = B_post - 8'd40;
        end
        else if(B_post > 8'd29) begin
            input_num8_next = 8'd3;
            input_num9_next = B_post - 8'd30;
        end
        else if(B_post > 8'd19) begin
            input_num8_next = 8'd2;
            input_num9_next = B_post - 8'd20;
        end    
        else if(B_post > 8'd9) begin
            input_num8_next = 8'd1;
            input_num9_next = B_post - 8'd10;
        end
        else begin
            input_num8_next = 8'd0;
            input_num9_next = B_post;
        end
    end
    always@(*) begin
        if(num == 8'd91) begin
            input_2 = 8'd10; // N
            input_1 = 8'd0;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(state == `player_A && num == A_money)begin
            input_2 = 8'd12; // L
            input_1 = 8'd12; // L
            input_4 = 8'd0;
            input_3 = 8'd11; // A
        end
        else if(state == `player_B && num == B_money)begin
            input_2 = 8'd12; // L
            input_1 = 8'd12; // L
            input_4 = 8'd0;
            input_3 = 8'd11; // A
        end
        else if(num > 8'd79) begin
            input_2 = 8'd8;
            input_1 = num - 8'd80;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(num > 8'd69) begin
            input_2 = 8'd7;
            input_1 = num - 8'd70;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(num > 8'd59) begin
            input_2 = 8'd6;
            input_1 = num - 8'd60;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(num > 8'd49) begin
            input_2 = 8'd5;
            input_1 = num - 8'd50;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(num > 8'd39) begin
            input_2 = 8'd4;
            input_1 = num - 8'd40;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(num > 8'd29) begin
            input_2 = 8'd3;
            input_1 = num - 8'd30;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else if(num > 8'd19) begin
            input_2 = 8'd2;
            input_1 = num - 8'd20;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end    
        else if(num > 8'd9) begin
            input_2 = 8'd1;
            input_1 = num - 8'd10;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
        else begin
            input_2 = 8'd0;
            input_1 = num;
            input_4 = 8'd0;
            input_3 = 8'd0;
        end
    end
    always@(posedge rst or posedge clk13) begin
        if(rst == 1'b1)
            DIGIT <= 4'b0000;
        else
            DIGIT <= now;
    end
    always@(*) begin
        case(ans)
            8'b00000000 : DISPLAY = 7'b1000000;
            8'b00000001 : DISPLAY = 7'b1111001;
            8'b00000010 : DISPLAY = 7'b0100100;
            8'b00000011 : DISPLAY = 7'b0110000;
            8'b00000100 : DISPLAY = 7'b0011001;
            8'b00000101 : DISPLAY = 7'b0010010;
            8'b00000110 : DISPLAY = 7'b0000010;
            8'b00000111 : DISPLAY = 7'b1111000;
            8'b00001000 : DISPLAY = 7'b0000000;
            8'b00001001 : DISPLAY = 7'b0010000;
            8'b00001010 : DISPLAY = 7'b1001000;
            8'b00001011 : DISPLAY = 7'b0001000;
            8'b00001100 : DISPLAY = 7'b1000111;
            default : DISPLAY = 7'b1111111;
        endcase
    end
    always@(*) begin
        case(DIGIT)
            4'b1110 : begin
                now = 4'b1101;
                ans = input_1;
            end
            4'b1101 : begin
                now = 4'b1011;
                ans = input_2;
            end
            4'b1011 : begin
                now = 4'b0111;
                ans = input_3;
            end
            4'b0111 : begin
                now = 4'b1111;
                ans = input_4;
            end
            default : begin
                now = 4'b1110;
                ans = input_1;
            end
        endcase
    end


endmodule