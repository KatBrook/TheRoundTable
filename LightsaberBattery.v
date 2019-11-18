// Filename: LightsaberBattery.v
// Author: Lizbeth Trevino
// Date: 11/7/2019
// Course: CS 4341.001
// Version 1.0
// Copyright 2019, All rights reserved.
//
// Description:
//	Battery???
//
// The software I have chosen is Icarus iVerilog.
// I installed Icarus iVerilog packages compiled with the MinGW toolchain for Windows from: http://bleyer.org/icarus/
// I specifically installed iverilog-v11-20190809-x64_setup.exe[17.0MB]
// To run Icarus iverilog I use the Windows Command Prompt
// Commands I used to run the program:
//	iverilog -o a.out lct170130.HW4.Program.v
//	vvp a.out
//----------------------------------------------------------------------

//----------------------------------------------------------------------
// Module for Decoder
//----------------------------------------------------------------------

module Dec(a,b);
    //Delare the inputs and outputs.
	
    input a;
    output [1:0] b;

    assign b = 1<<a;	//Shift left 1 bit

endmodule 

//----------------------------------------------------------------------
// Module for D Flip-Flop
//----------------------------------------------------------------------

module DFF(clk, in, out); 
   //Delare the inputs and outputs.

   parameter n = 1; 	//1 bit wide

   input clk; 	
   input [n-1:0] in; 
   output [n-1:0] out;

   //Declare the local variables

   reg [n-1:0] out; 

   always @(posedge clk) 	//This is the statement that makes the circuit behave with the clk tick
      out = in; 

endmodule 

//----------------------------------------------------------------------
// Module for 2-Channel, 4-Bit Multiplexer
//----------------------------------------------------------------------

module Mux2(a1, a0, s, b);
   //Delare the inputs and outputs.

   parameter k = 5;		//4 Bits Wide

   input [k-1:0] a1, a0;	//Channels 0 & 1
   input [2-1:0] s;		//One-hot select bits
   output[k-1:0] b;		

   //Assign b to the channel that whas selected

   assign b = ({k{s[1]}} & a1) | ({k{s[0]}} & a0);

endmodule

//----------------------------------------------------------------------
// Module for 4-Channel, 1-Bit Multiplexer
//----------------------------------------------------------------------

module Mux4(a3, a2, a1, a0, s, b);
   //Delare the inputs and outputs.

   parameter k = 7;		//4 Bits Wide

   input [k-1:0] a3, a2, a1, a0;  //Channels 0, 1, 2, & 3
   input [3:0] s;		 //One-hot select bits
   output[k-1:0] b;

   //Assign b to the channel that whas selected

   assign b = ({k{s[3]}} & a3) | ({k{s[2]}} & a2) | ({k{s[1]}} & a1) | ({k{s[0]}} & a0);

endmodule 

//----------------------------------------------------------------------
// Module for checking if state is charging or using lightsaber
//----------------------------------------------------------------------

module State (up, down);

   //Delare the inputs and outputs.

    input up;
    input down;

   //Check if in use or recharging

    always @(up, down)
    begin
    	if (down == 1)
    	begin
		$display("The power is draining.");
    	end

    	else if (up == 1)
    	begin
		$display("The power is charging.");
    	end

    	else //Not in use or recharging, error
    	begin
               $display("The power is being reset.");
    	end
    end
endmodule 

//----------------------------------------------------------------------
// Module for checking if the lightsaber is out of power
//----------------------------------------------------------------------

module CheckPower (power, up);

   //Delare the inputs and outputs.

    input[6:0] power;
    input up;

   //Check if lightsaber is out of power

    always @(power, up)
    begin
    	if (power == 0 && up == 0)
    	begin
		$display("The lightsaber power has run out of power. It must recharge fully before being used again.");
    	end

    	else if (power <= 10 && up == 0)
    	begin
		$display("The lightsaber power has reached critical levels.");
    	end

	else if (power == 100 && up == 1)
    	begin
		$display("The lightsaber power has been fully charged.");
    	end

    	else //Display power level
    	begin
               $display("The lightsaber power is at %d%%.", power);
    	end
    end
endmodule 


//----------------------------------------------------------------------
// Module for Up/Down/Load Saturation Counter
//----------------------------------------------------------------------

module SaturationCounter(clk, rst, up, down, load, loadMax, powerMode, in, out);
    //Delare the inputs and outputs.

    parameter n = 7;				//7 bits wide

    input clk, rst, up, load, loadMax;
    input down;
    input [2:0] powerMode;
    input [n-1:0] in;
    output [n-1:0] out;

    //Declare the local variables

    //wire [n-1:0] next, outpm1, outDown, outUp;

    wire [n-1:0] next, outpm1, outUp;
    wire [n-1:0] maxIn;
    wire [n-1:0] mux2out;
    wire [1:0] selectMax;

    reg[n-1:0] outDown;

    //Initialize the register that will hold the maximum of the saturation counter.

    Dec maxDec (loadMax, selectMax); 
    Mux2 #(n) muxSat (in , maxIn , selectMax, mux2out); 
    DFF #(n) maxcount(clk , mux2out, maxIn);


    //Check to see if power is being lost or if recharging

    State s(up, down);

    //See which power mode was selected and set the decrement counter    

    //PowerRate r(powerMode, decRate);

    //Initilize the main control for the counter.
    
    assign outUp = (maxIn > out) ? out + {{n-1{down}}, 4'b0101} : maxIn;	//Increment if maxIn is greater than out 
	
    always @(clk, rst, up, down, load, loadMax, powerMode, in, out)
    begin

    	if(powerMode == 3'b001)
    	begin
		outDown = (0 < out) ? (out - 4'b0001) : 0; 	//{{n-1{down}}, 4'b0001} : 0;
    	end
    	else if(powerMode == 3'b010)
    	begin
    		outDown = (0 < out) ? (out - 4'b0101) : 0; 	//{{n-1{down}}, 4'b0101} : 0;
    	end
    	else if(powerMode == 3'b100)
    	begin
    		outDown = (0 < out) ? (out - 4'b1010) : 0;	//{{n-1{down}}, 4'b1010} : 0;
    	end
    	else
    	begin
    		outDown = (0 < out) ? (out - 4'b0000) : 0;	//{{n-1{down}}, 4'b0000} : 0;
    	end
    end  

    //assign outDown = (0 < out) ? out + {{n-1{down}}, decRate} : 0; 		//Decrement if 0 is less than out   

    assign outpm1 = ({down} > 0) ? {outDown} : {outUp}; 			//Assign the final decision
    

   //Initilize the register that will hold the contents of the counter.

    DFF #(n) count (clk, next , out);

    //Initilize the multiplexer that will help decide the contents of the counter.

    Mux4 #(n) mux(out, in, outpm1, {n{1'b0}}, 
               { (~rst & ~up & ~down & ~load), 
                 (~rst & load), 
                 (~rst & (up | down)),
                 rst }, next);

   //Test to see if lightsaber has reached critical level, output an error message	

   CheckPower c(out, up);

endmodule

//----------------------------------------------------------------------
// Test Bench
//----------------------------------------------------------------------

module TestBench;
    //Declare the inputs.

    parameter n = 7;	//5 bits wide

    reg clk, rst; 
    reg up, load, loadMax; 
    reg down;
    reg [n-1:0]  in;
    reg [2:0] powerMode = 010;

    //Declare the outputs.

    wire [n-1:0] out;
    wire [5:0] outputs;

    //Initilize the saturation counter.

    SaturationCounter satCnt(clk, rst, up, down, load, loadMax, powerMode, in, out);

    // Display the contents of the saturation counter for every cycle of 10.

      initial begin
	 //Start the clk

         clk = 1;
	 #5 clk = 0;

	 //Display the header for the table

	 $display(" CLK | RST | UP | DOWN | LOAD | LOADMAX | POWERMODE | IN | MAX | OUT ");
	 $display("-----+-----+----+------+------+---------+-----------+------+-----+-----");

         forever begin
	    //Display the output in a table

	    $display("  %b  |  %b  |  %b |   %b  |   %b  |    %b    |    %3b    | %d | %d  | %d", clk, rst, up, down, load, loadMax, powerMode, in, satCnt.maxIn, out);

            #5 clk = 1;

	    $display("  %b  |  %b  |  %b |   %b  |   %b  |    %b    |    %3b    | %d | %d  | %d", clk, rst, up, down, load, loadMax, powerMode, in, satCnt.maxIn, out);

            #5 clk = 0;

       end 

    end

    //Set the stimulus for the saturation counter.

    initial begin 

        //Reset the counter to 0

        rst = 0;
        #0 

        //#15 rst = 1;
        //#10 rst = 0;

        // Test loads

	//Decrement based on power mode
	
	//Set in to 100

	//#10 up = 0; down = 0; load = 0; loadMax = 0; in = 7'b0000000;
        #10 up = 0; down = 0; load = 0; loadMax = 0; in = 7'b1100100;  //in = 100 

	//Set loadMax to 1 to load 100 into the maximum register

        #10 up = 0; down = 0; load = 0; loadMax = 1; in = 7'b1100100;  //in = 100

	//Set load to 1 to load 100 into the count register

        #20 up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;  //in = 100

	//Set in to 0 and load to 0 as 100 has been loaded into the count register
	//Reset all commands

        #20 up = 0; down = 0; load = 0; loadMax = 0; in = 7'b0000000;  //in = 0

	//Set command to count down

        #20 up = 0; down = 1; load = 0; loadMax = 0; in = 7'b0000000;  //in = 0
	
	//Delay for a sufficient time to show the output should stop at 0

	#500

	//Hit error state and recharge 

	//Set in to 0 and loadMax to 0 as 100 has been loaded into the maximum register

        //#10 up = 0; down = 0; load = 0; loadMax = 0; in = 7'b0000000;  //in = 0

	//Load 0 into the count register

        //#10 up = 0; down = 0; load = 1; loadMax = 0; in = 7'b0000000;  //in = 0

	//Reset all commands

        //#10 up = 0; down = 0; load = 0; loadMax = 0; in = 7'b0000000;  //in = 0

	//Set command to count up

        #10 up = 1; down = 0; load = 0; loadMax = 0; in = 7'b0000000;  //in = 0	

	//Delay for a sufficient time to show the output should stop at 31

	#500
 
       //Finish the program

       $finish;

    end 

endmodule