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

module DFFBattery(clk, in, out); 
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

module Mux2Battery(a1, a0, s, b);
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

module Mux4Battery(a3, a2, a1, a0, s, b);
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

module batteryState (up, down, switch);

   //Delare the inputs and outputs.

    input up;
    input down;
    input [1:0] switch;

   //Check if in use or recharging

    always @(up, down, switch)
    begin
	if(switch == 2'b10)
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
	else
	begin
		$display("The power isn't affected if the lightsaber if turned off.");
	end
    end
endmodule

//----------------------------------------------------------------------
// Module for checking if the lightsaber is out of power
//----------------------------------------------------------------------

module CheckPower (power, up, switch);

   //Delare the inputs and outputs.

    input[6:0] power;
    input up;
    input [1:0] switch;

   //Check if lightsaber is out of power

    always @(power, up, switch)
    begin
	if(switch == 2'b10)
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
	else
	begin
		$display("The lightsaber cannot show it's power leves if it is turned off.");
	end
    end
endmodule

//----------------------------------------------------------------------
// Module for Up/Down/Load Saturation Counter
//----------------------------------------------------------------------

module Battery(clk, rst, switch, up, down, load, loadMax, powerMode, in, out);
    //Delare the inputs and outputs.

    parameter n = 7;				//7 bits wide

    input clk, rst, up, load, loadMax;
    input down;
    input [2:0] powerMode;
    input [n-1:0] in;
    input [1:0] switch;
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
    Mux2Battery #(n) muxSat (in , maxIn , selectMax, mux2out); 
    DFFBattery #(n) maxcount(clk , mux2out, maxIn);


    //Check to see if power is being lost or if recharging

    batteryState s(up, down, switch);

    //Initilize the main control for the counter.
    
    assign outUp = (maxIn > out) ? out + {{n-1{down}}, 4'b0101} : maxIn;	//Increment if maxIn is greater than out 
	
    always @(clk, rst, up, down, load, loadMax, powerMode, in, out)
    begin

    	if(powerMode == 3'b001)
    	begin
		outDown = (0 < out) ? (out - 4'b0001) : 0; 	
    	end
    	else if(powerMode == 3'b010)
    	begin
    		outDown = (0 < out) ? (out - 4'b0101) : 0; 	
    	end
    	else if(powerMode == 3'b100)
    	begin
    		outDown = (0 < out) ? (out - 4'b1010) : 0;
    	end
    	else
    	begin
    		outDown = (0 < out) ? (out - 4'b0000) : 0;	
    	end
    end  

    //assign outDown = (0 < out) ? out + {{n-1{down}}, decRate} : 0; 		//Decrement if 0 is less than out   

    assign outpm1 = ({down} > 0) ? {outDown} : {outUp}; 			//Assign the final decision
    

   //Initilize the register that will hold the contents of the counter.

    DFF #(n) count (clk, next , out);

    //Initilize the multiplexer that will help decide the contents of the counter.

    Mux4Battery #(n) mux(out, in, outpm1, {n{1'b0}}, 
               { (~rst & ~up & ~down & ~load), 
                 (~rst & load), 
                 (~rst & (up | down)),
                 rst }, next);

   //Test to see if lightsaber has reached critical level, output an error message	

   CheckPower c(out, up, switch);

endmodule





//-----------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------

//D Flip-flop-----------------------------------------------------------
module DFFPowerMode(clk, in, out);
	parameter n = 1;
	input   clk;
	input   [n-1:0] in;
	output  [n-1:0] out;
	reg     [n-1:0] out;
	
	always @(posedge clk)
	out = in;	
endmodule
//----------------------------------------------------------------------

//Power Setting Module--------------------------------------------------
module PowerSetting(clk, switch, powIn, powOut);
    input [2:0] powIn; //training 001, dueling 010, or bulkheads 100
    input clk;
    input [1:0] switch;
    output [2:0] powOut;
    wire [2:0] powOut;

    DFFPowerMode A0 (clk, powIn[0], powOut[0]);
    DFFPowerMode A1 (clk, powIn[1], powOut[1]);
    DFFPowerMode A2 (clk, powIn[2], powOut[2]);

    printMode powerMode(powOut, switch);
 
endmodule
//----------------------------------------------------------------------

module printMode(out, switch);
	
	input [2:0] out;
	input [1:0] switch;

	always @(out, switch)
	begin	
		if(switch == 2'b10)
		begin
			if(out == {3'b001}) 
			begin
           		    $display ("Power Setting - Training");
        		end 
			else if (out == {3'b010}) 
			begin
          		    $display ("Power Setting - Dueling");
        		end 
			else if (out == {3'b100}) 
			begin
           		    $display ("Power Setting - Bulkhead");
        		end 
			else 
			begin
            	   	 $display ("Power Setting - Error - Bad Input");
       			end
		end
		else
		begin
			$display("You cannot choose a power mode if the lightsaber is turned off.");
		end
	end
endmodule

//---------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------

//============================================
// Define Configuration Opcode
//===========================================

`define NP 2'b00
`define S 2'b01 //2 Bit, One Hot
`define D 2'b10 //2 Bit, One Hot
`define H 2'b11 //2 Bit, One Hot

//=============================================
// 4-Channel, 2-Bit Multiplexer for Blade Configuration
//=============================================

module Mux4Blade(state,s, b) ;
	parameter k = 2 ;//Two Bits Wide
	input [k-1:0] state ;  // inputs
	input [1:0]   s ; // one-hot select
	output[k-1:0] b ;

	assign b = ({k{s[0]&~s[1]}} & `S) | ({k{~s[0]&s[1]}} & `D) | ({k{s[0]&s[1]}} & `H) |  ({k{(~s[0] & ~s[1])}} & state); 

endmodule

//=============================================
// Configuration Control
//=============================================
module ConfigurationControl(clk, switch, select);

//---------------------------------------------
//Parameters
//---------------------------------------------
input clk;
input rst;
input trigger;
input[1:0] select, switch; //The selection for the multiplexer
//---------------------------------------------
//Local Variables
//---------------------------------------------
wire [1:0] muxout;//The output for the mulitplexer
wire [1:0] feedback;//The feedback from the D Flip-Flops
reg  [1:0] gateout;//The output from the characteristic equations
reg  [1:0]  state; //The state of current color
//wire [1:0] s;//select for Mux
//==Create the two Flip-Flops, and plug them into the circuit
DFFConfig A(clk, gateout, feedback) ;

//==The MUX with its inputs, the select, and its output
// Channel 0 is Feedback, The value of the previous state/current state
// Channel 1 is Single 
// Channel 2 is Double
// Channel 3 is Hilt
// S has to be  00,01,10,11

Mux4Blade iMux(state,select,muxout);

printBladeConfig printConf(state, switch);

//DFF A(clk,gateout,feedback);

//==These statements are are procedural, not parallel==

always @(*) begin

//==Update value on the MUX==
//s={1'b1,1'b1,select[1],select[0]};
   		
//==Results of mux goes to muxout==
//(thread)

//==Feed the results of the mux to the Gates==
//Math is trivial in this case, reduces to trigger.
//Feedback from flip-flops is not needed.
//A more complicated system would have more equations
//And equations for output.
  
gateout[1] = muxout[1];
gateout[0] = muxout[0];

//==The current state is based on the flip-flops==
//(Thread)
//Find the next state
state={gateout[1],gateout[0]};//Set the state equal to the value of the flip flops
end

endmodule

module printBladeConfig(state, switch);

	input [1:0] state, switch;

	always @(state, switch)
	begin
		if(switch == 2'b10)
		begin
			if(state == 2'b01)
			begin
				$display("The lightsaber has a single blade.");
			end
			else if(state == 2'b10)
			begin
				$display("The lightsaber has dual blades.");
			end
			else if(state == 2'b11)
			begin
				$display("The lightsaber is hilted.");
			end
			else
			begin
				$display("No-Op");
			end
		end
		else
		begin
			$display("You cannot choose a blade configuration if the lightsaber is turned off.");
		end
	end

endmodule



//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------

//============================================
// Define Color Opcode
//===========================================

`define NP 2'b00
`define R 2'b01 //2 Bit, One Hot
`define B 2'b10 //2 Bit, One Hot
`define G 2'b11 //2 Bit, One Hot

//=============================================
// 4-Channel, 2-Bit Multiplexer for Color
//=============================================

module Mux4Color(state,s, b) ;
	parameter k = 2 ;//Two Bits Wide
	input [k-1:0] state ;  // inputs
	input [1:0]   s ; // one-hot select
	output[k-1:0] b ;

	assign b = ({k{s[0]&~s[1]}} & `R) | ({k{~s[0]&s[1]}} & `B) | ({k{s[0]&s[1]}} & `G) |  ({k{(~s[0] & ~s[1])}} & state); 
endmodule

//=============================================
// D Flip-Flop
//=============================================
module DFFConfig(clk,in,out);

  parameter n=2;
  input  clk;
  input [n-1:0]  in;
  output [n-1:0] out;
  reg    [n-1:0] out;
  
  always @(posedge clk)//<--This is the statement that makes the circuit behave with TIME
	  out = in;
endmodule

//=============================================
// Color Automata
//=============================================
module ColorControl(clk, switch, select);

//---------------------------------------------
//Parameters
//---------------------------------------------
input clk;
input rst;
input trigger;
input[1:0] select, switch; //The selection for the multiplexer
//---------------------------------------------
//Local Variables
//---------------------------------------------
output [1:0] muxout;//The output for the mulitplexer
wire [1:0] feedback;//The feedback from the D Flip-Flops
reg  [1:0] gateout;//The output from the characteristic equations
reg  [1:0]  state; //The state of current color
//wire [1:0] s;//select for Mux

//==Create the two Flip-Flops, and plug them into the circuit
DFFConfig A(clk, gateout, feedback) ;

//==The MUX with its inputs, the select, and its output
// Channel 0 is Feedback, The value of the previous state/current state
// Channel 1 is Red 
// Channel 2 is Blue
// Channel 3 is Green
// S has to be  00,01,10,11

Mux4Color iMux(state,select,muxout);

printColor outColor(state, switch);

//==These statements are are procedural, not parallel==

always @(*) begin

//==Update value on the MUX==
//s={1'b1,1'b1,select[1],select[0]};
   		
//==Results of mux goes to muxout==
//(thread)

//==Feed the results of the mux to the Gates==
//Math is trivial in this case, reduces to trigger.
//Feedback from flip-flops is not needed.
//A more complicated system would have more equations
//And equations for output.
  

gateout[1] = muxout[1];
gateout[0] = muxout[0];

//==The current state is based on the flip-flops==
//(Thread)
//Find the next state
state={gateout[1],gateout[0]};//Set the state equal to the value of the flip flops
end

endmodule

//-----------------------------------------------------
// Module for printing out the color of the lightsaber.
//-----------------------------------------------------

module printColor(state, switch);

	input [1:0] state, switch;

	always @(state, switch)
	begin
		if(switch == 2'b10)
		begin
			if(state == 2'b01)
			begin
				$display("The color of the lightsaber is red.");
			end
			else if(state == 2'b10)
			begin
				$display("The color of the lightsaber is blue.");
			end
			else if(state == 2'b11)
			begin
				$display("The color of the lightsaber is green.");
			end
			else
			begin
				$display("No-Op");
			end
		end
		else
		begin
			$display("You cannot choose a color for your lightsaber if it is turned off.");
		end
	end

endmodule


//-----------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------

//=============================================
//Light Switch Digital Abstraction State Labels
//Make them One-Hot
//=============================================
`define StateOff 2'b01 //2 Bit, One Hot
`define StateOn  2'b10 //2 Bit, One Hot


//=============================================
//Light Switch Trigger/Transactions
//Light is on when lightswitch is up
//Light is off when lightswitch is down
//=============================================
`define FlipDown 1'b0
`define FlipUp   1'b1

//=============================================
// D Flip-Flop
//=============================================
module switchDFF(clk,in,out);
  
  input  clk;
  input  in;
  output out;
  reg    out;
  
  always @(posedge clk)//<--This is the statement that makes the circuit behave with TIME
  out = in;
 endmodule

 
//=============================================
// 4-Channel, 2-Bit Multiplexer
//=============================================

module switchMux4(a3, a2, a1, a0, s, b) ;
	parameter k = 2 ;//Two Bits Wide
	input [k-1:0] a3, a2, a1, a0 ;  // inputs
	input [3:0]   s ; // one-hot select
	output[k-1:0] b ;
	assign b = ({k{s[3]}} & a3) | 
               ({k{s[2]}} & a2) | 
               ({k{s[1]}} & a1) |
               ({k{s[0]}} & a0) ;
endmodule

//=============================================
// Light Switch Automata
//=============================================
module OnOffSwitch(clk, rst, trigger);

//---------------------------------------------
//Parameters
//---------------------------------------------
input clk;
input rst;
input trigger;

//---------------------------------------------
//Local Variables
//---------------------------------------------
reg  [1:0] state;//The state
reg  [3:0] select;//The selection for the multiplexer
wire [1:0] muxout;//The output for the mulitplexer
wire [1:0] feedback;//The feedback from the D Flip-Flops
reg  [1:0] gateout;//The output from the characteristic equations


//==Create the two Flip-Flops, and plug them into the circuit
switchDFF highBit(clk, gateout[1], feedback[1]) ;
switchDFF lowBit (clk, gateout[0], feedback[0]) ; 

//==The MUX with its inputs, the select, and its output
// Channel 0 is Feedback, The value of the previous state/current state
// Channel 1 is Reset
// Channel 2 is Don't Care
// Channel 3 is Don't Care
// S has to be  0001 if RST is low
// S has to be  0010 if RST is high
switchMux4 iMux(2'b00,2'b00,2'b01,state,select,muxout);

//==These statements are are procedural, not parallel==
always @(*) begin



//==Update value on the MUX==
select={1'b0,1'b0,rst,~rst};

//==Results of mux goes to muxout==
//(thread)

//==Feed the results of the mux to the Gates==
//Math is trivial in this case, reduces to trigger.
//Feedback from flip-flops is not needed.
//A more complicated system would have more equations
//And equations for output.
gateout={trigger,~trigger};

//==The current state is based on the flip-flops==
//(Thread)
//Find the next state
state={highBit.out,lowBit.out};//Set the state equal to the value of the flip flops

end

endmodule




//-----------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

module DFF(clk, in, out); 
   //Delare the inputs and outputs.

   parameter n = 16; 	//16 bit wide

   input clk; 	
   input [n-1:0] in; 
   output [n-1:0] out;

   //Declare the local variables

   reg signed [n-1:0] out; 

   always @(posedge clk) 	//This is the statement that makes the circuit behave with the clk tick
      out = in; 

endmodule

//----------------------------------------------------------------------
// Module for 4-Channel, 16-Bit Multiplexer
//----------------------------------------------------------------------

module Mux4(a3, a2, a1, a0, s, b);
   //Delare the inputs and outputs.

   parameter k = 16;		//16 Bits Wide

   input [k-1:0] a3, a2, a1, a0;  //Channels 0, 1, 2, & 3
   input [3:0] s;		 		  //one-hot select
   output[k-1:0] b;

   //Assign b to the channel that whas selected

   assign b = ({k{s[3]}} & a3) | ({k{s[2]}} & a2) | ({k{s[1]}} & a1) | ({k{s[0]}} & a0);

endmodule 

//----------------------------------------------------------------------
// Module for checking if the given length is valid
//----------------------------------------------------------------------

module checkLength(bladeConfig, switch, maxL, maxR, floatL, floatR, hiltLength, lengthL, lengthR, lengthH);

    input [1:0] bladeConfig, switch;
    input [15:0] maxL, maxR, floatL, floatR, hiltLength;
    output [15:0] lengthL, lengthR, lengthH;

    reg signed [15:0] lengthL, lengthR, lengthH;

    always @ (bladeConfig, switch, maxL, maxR, floatL, floatR, hiltLength, lengthL, lengthR, lengthH)
	begin
	if(switch == 2'b10)
	begin
	    if(bladeConfig == 0)
	    begin
		$display("No blade configuration, cannot set the blade length.");

		lengthL = 0;
		lengthR = 0;
		lengthH = 0;
	    end
	    else
	    begin
		if(floatL[15] == 1 || floatR[15] == 1)    //Negative numbers -> reject, set to 0.5 m
		begin
			$display("Even though your ability to use the force can help you defy the laws of physics, it does not mean you can have a negative blade length.");
			$display("The blade length has been set to 0.5 meters to try and compensate for your lack of intelligence.");

			lengthL = 0;
			lengthR = 50;
		end
		else if(floatL == 0 && floatR == 0)  //0.0 -> reject, set to 0.5 m
		begin
			$display("If Master Yoda needs a blade length greater than 0.0 m to fight Darth Vader, then I highly doubt you can go without a blade at all.");
			$display("The blade length has been set to 0.5 meters to try and counteract your hubris.");

			lengthL = 0;
			lengthR = 50;
		end
		else if(floatL == 0 && floatR < maxR) // 0.1 - 0.99 -> accept, no-change
		begin
			lengthL = floatL;
			lengthR = floatR;
		end
		else if(floatL == 0 && floatR == 100) // 0.100 -> accept, convert to 1.0 m
		begin
			$display("I see you have decided to go with 100 cm instead of the customary 1.0 meters young padawan.");

			lengthL = 1;
			lengthR = 0;
		end
		else if(floatL == 0 && floatR > maxR) //0.101 and greater -> reject, set to 1.0 m
		begin
			$display("Are you trying to compensate for a lack of training young padawan?");
			$display("The blade length cannot exceed 1.0 meters. It has been set to the maximum allowed length.");

			lengthL = 1;
			lengthR = 0;
		end
		else if(floatL == maxL && floatR == 0) //1.0 -> accept, no-change
		begin
			lengthL = floatL;
			lengthR = floatR;
		end
		else if(floatL == maxL && floatR > 0) //1.01 and greater -> reject, set to 1.0 m
		begin
			$display("Are you trying to compensate for a lack of training young padawan?");
			$display("The blade length cannot exceed 1.0 meters. It has been set to the maximum allowed length.");

			lengthL = 1;
			lengthR = 0;
		end
		else
		begin
			$display("You have a faulty lightsaber. May the Force be with you.");
		end


		if(bladeConfig == 16'b0000000000000001)
		begin
			$display("Your single blade has a length of %2d.%02d meters.", lengthL, lengthR);
			lengthH = 16'sb0000000000000000;
		end
		else if(bladeConfig == 16'b0000000000000010)
		begin
			$display("Both of your blades have a length of %2d.%02d meters.", lengthL, lengthR);
			lengthH = 16'sb0000000000000000;
		end
		else if(bladeConfig == 16'b0000000000000011)
		begin
			$display("Your single blade has a length of %2d.%02d meters and your hilts have a set size of %02d cm.", lengthL, lengthR, lengthH);
			lengthH = 16'sb0000000000001010;
		end

	    end
	end
	else
	begin
		//$display("The Lightsaber has been turned off.");
		lengthL = 0;
		lengthR = 0;
		lengthH = 0;

	end
	end

endmodule

//---------------------------------------------------------------------
// Module for setting the length of the blade
//---------------------------------------------------------------------

module SetLength(clk, rst, switch, maxL, maxR, floatL, floatR, hiltLength, bladeConfig, outL, outR, outH);

    input clk, rst;
    input [1:0] bladeConfig, switch;
    input [15:0] maxL, maxR, muxHOut, floatL, floatR, hiltLength;
    output [15:0] outL, outR, outH;

    reg [3:0] select;
    reg signed [15:0] outL, outR, outH;
    wire signed [15:0] muxLOut, muxROut, muxHOut, feedbackL, feedbackR, feedbackH, setL, setR, setH;

    reg signed [2:0] state;		//The state, 2 bits, leftright	
    reg signed [15:0] gateoutL, gateoutR, gateoutH;		//The output from the characteristic equations


    DFF leftReg[15:0](clk, muxLOut, feedbackL);
    DFF rightReg[15:0](clk, muxROut, feedbackR);
    DFF hiltReg[15:0](clk, muxHOut, feedbackH);

    // The MUX with its inputs, the select, and its output
    // Channel 0 is Feedback, The value of the previous state/current state/State Equation
    // Channel 1 is Load Length, length from check length
    // Channel 2 is Don't Care
    // Channel 3 is Don't Care

    Mux4 leftMux(16'sb0000000000000000, 16'sb0000000000000000, feedbackL, gateoutL, select, muxLOut);
    Mux4 rightMux(16'sb0000000000000000, 16'sb0000000000000000, feedbackR, gateoutR, select, muxROut);
    Mux4 hiltMux(16'sb0000000000000000, 16'sb0000000000000000, feedbackH, gateoutH, select, muxHOut);

    checkLength newLength(bladeConfig, switch, maxL, maxR, floatL, floatR, hiltLength, setL, setR, setH); 

    always @(*) 
    begin

	select = {1'b0,1'b0,rst,~rst};

	outL = feedbackL;  //Used to be feedbackL, in HW3 he used .out instead of feedback to get the output of the DFF
	outR = feedbackR;  //Used to be feedbackR
	outH = feedbackH;

	//==Feed the results of the mux to the Gates==
	//Math is trivial in this case, reduces to trigger.
	//Feedback from flip-flops is not needed.
	//A more complicated system would have more equations
	//And equations for output.

	gateoutL = setL;
	gateoutR = setR;
	gateoutH = setH;

	//==The current state is based on the flip-flops==
	//(Thread)
	//Find the next state

	state = {feedbackL, feedbackR, feedbackH}; //Set the state equal to the value of the flip flops

    end


endmodule

//----------------------------------------------------------------------
// Test Bench
//----------------------------------------------------------------------

module testbench();

    //Variables for setting the length

    parameter n = 16;	//5 bits wide
    reg clk, rst; 
    reg [n-1:0] maxL = 16'sb0000000000000001;  //Max of 1 meter on the left of decimal
    reg [n-1:0] maxR = 16'sb0000000001100011;  //Max of 99 cm on the right of decimal
    reg signed [n-1:0] floatL, floatR, hiltLength;
    //reg [1:0] bladeConfig = 2'b10;
     wire signed [n-1:0] outLeft, outRight, outHilt;

    //Variables for turing the lightsaber off and on

    reg trigger ;
    wire outOnOff;
    reg [1:0] oldval;
    reg [1:0] newval;
  
    //Variables for setting the color.

    reg [1:0] oldColor;
    reg [1:0] colorSelect;

    //Variables for setting the blade configuration.

    reg [1:0] oldBlade;
    reg [1:0] bladeSelect;

    //Variables for setting the power mode.

    reg  [2:0] in;
    wire [2:0] out;

    //Variables for the battery

    reg up, down, load, loadMax;
    reg [6:0] batteryIn;
    wire [6:0] batteryOut;


    //Initilize the saturation counter.

    Battery bat(clk, rst, LightSwitch.state, up, down, load, loadMax, out, batteryIn, batteryOut);

    PowerSetting zap(clk, LightSwitch.state, in, out);

    ConfigurationControl Configuration(clk, LightSwitch.state, bladeSelect);

    ColorControl ColorChange(clk, LightSwitch.state, colorSelect);

    OnOffSwitch LightSwitch(clk, rst, trigger);

    SetLength bladeLength(clk, rst, LightSwitch.state, maxL, maxR, floatL, floatR, hiltLength, Configuration.state, outLeft, outRight, outHilt);

    // Display the contents of the saturation counter for every cycle of 10.

      initial begin
	 //Start the clk

         clk = 1;
	 #5 clk = 0;

	 //Display the header for the table

	 $display(" CLK | RST | Trigger | Current | Max Length | Desired Length | Blade Length | Hilt Length | Current Color | Next Color | Current Blade Config | Blade Config | Power Mode | UP | DOWN | LOAD | LOADMAX | IN | MAX | Power Levels");
	 $display("-----+-----+---------+---------+------------+----------------+--------------+-------------+---------------+------------+----------------------+--------------+------------+----+------+------+---------+----+-----+-------------");

         forever begin
	    //Display the output in a table

	    $display("  %b | %b | %b | %b | %2d.%02d m |  %2d.%02d m | %2d.%02d m | 0.%02d | %b | %b | %2d | %2d | %3b | %b | %b | %b | %b | %3d | %3d | %3d ", clk, rst, trigger, LightSwitch.state, maxL, maxR, floatL, floatR, outLeft, outRight, outHilt, oldColor, ColorChange.state, oldBlade, Configuration.state, out, up, down, load, loadMax, batteryIn, bat.maxIn, batteryOut);
	    oldval=LightSwitch.state;
	    oldColor = ColorChange.state;
	    oldBlade = Configuration.state;

            #5 clk = 1;

	    $display("  %b | %b | %b | %b | %2d.%02d m |  %2d.%02d m | %2d.%02d m | 0.%02d | %b | %b | %2d | %2d | %3b | %b | %b | %b | %b | %3d | %3d | %3d ", clk, rst, trigger, LightSwitch.state, maxL, maxR, floatL, floatR, outLeft, outRight, outHilt, oldColor, ColorChange.state, oldBlade, Configuration.state, out, up, down, load, loadMax, batteryIn, bat.maxIn, batteryOut);
	    oldval=LightSwitch.state;
	    oldColor = ColorChange.state;
	    oldBlade = Configuration.state;

            #5 clk = 0;

       end 

    end

    //Set the stimulus for the saturation counter.

    initial begin 

        // Test loads
	
	//#30 rst = 1; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b00;  //Set length to -1.00 m
	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b01; //Set length to -1.00 m
	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b10; //Set length to -1.00 m
	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b11; //Set length to -1.00 m

	//#50

	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b01; //Set length to 0.-01 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b10; //Set length to 0.-01 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b11; //Set length to 0.-01 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b00; //Set length to 0.-01 m

	//#50

	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b01; //Set length to -1.-01 m
	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b10; //Set length to -1.-01 m
	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b11; //Set length to -1.-01 m
	//#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b00; //Set length to -1.-01 m

	//#50

        //#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b01; //Set length to 0.00 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b10; //Set length to 0.00 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b11; //Set length to 0.00 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b00; //Set length to 0.00 m

	//#50

        //#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b01; //Set length to 0.23 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b10; //Set length to 0.23 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b11; //Set length to 0.23 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b00; //Set length to 0.23 m

	//#50

        ///#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b01; //Set length to 0.50 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b10; //Set length to 0.50 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b11; //Set length to 0.50 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b00; //Set length to 0.50 m

	//#50	

	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b01; //Set length to 0.100 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b10; //Set length to 0.100 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b11; //Set length to 0.100 m
	//#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b00; //Set length to 0.100 m

	//#50

        //#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; bladeConfig = 2'b01; //Set length to 1.00 m

	
	
	//#1500
	
	
	
	#30 rst = 1; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; ColorChange.gateout = 2'b01; colorSelect=`B; in = 3'b100; up = 0; down = 0; load = 0; loadMax = 0; in = 7'b0000000;  //Set length to 1.00 m
	//rst = 0;
	//#0

	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001; up = 0; down = 0; load = 0; loadMax = 0; in = 7'b1100100;  //in = 0
	//#100	
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001; up = 0; down = 0; load = 0; loadMax = 0; in = 7'b1100100;  //in = 100
	//#100	
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001; up = 0; down = 0; load = 0; loadMax = 1; in = 7'b1100100;  //in = 100
	//#100
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;  //in = 100
	//#100	
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001; up = 0; down = 0; load = 0; loadMax = 0; in = 7'b1100100;  //in = 0
	//#100	
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001;	up = 0; down = 0; load = 0; loadMax = 1; batteryIn = 7'b1100100;	//Set length to 1.00 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001;	up = 0; down = 0; load = 1; loadMax = 0; batteryIn = 7'b1100100;
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001;	up = 0; down = 1; load = 0; loadMax = 0; batteryIn = 7'b1100100;
	
	#1000	

	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = 3'b001;	up = 1; down = 0; load = 0; loadMax = 0; batteryIn = 7'b1100100;

	#250

		//Set lengt
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `B; bladeSelect = `D; in = 3'b100; up = 0; down = 1; load = 0; loadMax = 0; batteryIn = 7'b1100100;	//Set length to 1.00 m
	//#25000	

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `R; bladeSelect = `S; in = {3'b001};	up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `R; bladeSelect = `S; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1500	

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `G; bladeSelect = `H; in = {3'b001};	up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `G; bladeSelect = `H; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1500
	
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `NP; bladeSelect = `NP; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `NP; bladeSelect = `NP; in = {3'b00}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1500

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = {3'b010};	up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `B; bladeSelect = `D; in = {3'b010}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1500
	
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `R; bladeSelect = `S; in = {3'b010};	up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `R; bladeSelect = `S; in = {3'b010}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1000	

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `G; bladeSelect = `H; in = {3'b010};	up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `G; bladeSelect = `H; in = {3'b010}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1000	

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `NP; bladeSelect = `NP; in = {3'b010}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `NP; bladeSelect = `NP; in = {3'b010}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m	
	//#1000

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `B; bladeSelect = `D; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `B; bladeSelect = `D; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1000	

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `R; bladeSelect = `S; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `R; bladeSelect = `S; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1000
	
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `G; bladeSelect = `H; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `G; bladeSelect = `H; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1000
	
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipUp; colorSelect = `NP; bladeSelect = `NP; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; trigger=`FlipDown; colorSelect = `NP; bladeSelect = `NP; in = {3'b001}; up = 0; down = 0; load = 1; loadMax = 0; in = 7'b1100100;	//Set length to 1.00 m
	//#1000
	
	//#10 up = 1; down = 0; load = 0; loadMax = 0; in = 7'b0000000;  //in = 0	
	
	//#1500 

	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b01; //Set length to 1.01 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b10; //Set length to 1.01 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b11; //Set length to 1.01 m
	//#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b00; //Set length to 1.01 m

 
       //Finish the program

       $finish;

    end 

endmodule //Close the testbench module