
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
module DFF(clk,in,out);
  
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

module Mux4(a3, a2, a1, a0, s, b) ;
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
module Breadboard(clk, rst,trigger);

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
DFF highBit(clk, gateout[1], feedback[1]) ;
DFF lowBit (clk, gateout[0], feedback[0]) ; 

//==The MUX with its inputs, the select, and its output
// Channel 0 is Feedback, The value of the previous state/current state
// Channel 1 is Reset
// Channel 2 is Don't Care
// Channel 3 is Don't Care
// S has to be  0001 if RST is low
// S has to be  0010 if RST is high
Mux4 iMux(2'b00,2'b00,2'b01,state,select,muxout);

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

//=============================================
// Test Bench
//=============================================
module Test_FSM() ;

//---------------------------------------------
//Inputs
//---------------------------------------------
  reg clk;
  reg rst;
  reg trigger ;

  wire out;
  
  reg [1:0] oldval;
  reg [1:0] newval;
  
  
//---------------------------------------------
//Declare FSM
//---------------------------------------------  
  Breadboard LightSwitch(clk, rst,trigger);
  
//---------------------------------------------
//The Display Thread with Clock Control
//---------------------------------------------
   initial
    begin
	  forever
			begin
					#5 
					clk = 0 ;
					#5
					clk = 1 ;
			end
   end	

   

//---------------------------------------------
//The Display Thread with Clock Control
//---------------------------------------------
   initial
    begin
	  #1 ///Offset the Square Wave
      $display("CLK|RST|TRG|Old|Current|");
      $display("---+---+---+---+-------|");
	  forever
			begin
			#5
					$display(" %b | %b | %b | %b|     %b|",clk,rst,trigger,oldval,LightSwitch.state);
					oldval=LightSwitch.state;
			end
   end	

   
   
   
//---------------------------------------------   
// The Input Stimulous.
// Flipping the switch up and down.
//---------------------------------------------   
   
   
  initial 
	begin
	    #2 //Offset the Square Wave
		#10 rst = 0 ; trigger=`FlipDown;
		#10 rst = 1 ; trigger=`FlipDown;
		
		#10 rst = 0 ; trigger=`FlipUp;
		#10 rst = 0 ; trigger=`FlipDown;
		#10 rst = 0 ; trigger=`FlipUp;
		#10 rst = 0 ; trigger=`FlipDown;
		#10 rst = 0 ; trigger=`FlipUp;
		#10 rst = 0 ; trigger=`FlipDown;
		#10 rst = 0 ; trigger=`FlipUp;
		#10 rst = 0 ; trigger=`FlipDown;
		#10 rst = 0 ; trigger=`FlipUp;
		#10 rst = 0 ; trigger=`FlipDown;
		
		
		$finish;
	end
	
	
endmodule

 
