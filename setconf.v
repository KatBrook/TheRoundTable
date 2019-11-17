//============================================
// Define Configuration Opcode
//===========================================

`define NP 2'b00
`define S 2'b01 //2 Bit, One Hot
`define D 2'b10 //2 Bit, One Hot
`define H 2'b11 //2 Bit, One Hot

//=============================================
// D Flip-Flop
//=============================================
module DFF(clk,in,out);

  parameter n=2;
  input  clk;
  input [n-1:0]  in;
  output [n-1:0] out;
  reg    [n-1:0] out;
  
  always @(posedge clk)//<--This is the statement that makes the circuit behave with TIME
	  out = in;
endmodule
 
 //=============================================
// 4-Channel, 2-Bit Multiplexer
//=============================================

module Mux4(state,s, b) ;
	parameter k = 2 ;//Two Bits Wide
	input [k-1:0] state ;  // inputs
	input [1:0]   s ; // one-hot select
	output[k-1:0] b ;

	assign b = ({k{s[0]&~s[1]}} & `S) | ({k{~s[0]&s[1]}} & `D) | ({k{s[0]&s[1]}} & `H) |  ({k{(~s[0] & ~s[1])}} & state); 
//	assign b[1] = s[1] | (state[1]&~s[1]&~s[0]);
//	assign b[0] = s[0] | (state[0]&~s[1]&~s[0]);
//	assign b[1] = (state[1]&~s[0]) | (state[0]&s[1]) | (state[1]&s[1]);
//	assign b[0] = (state[0]&~s[1]) | (state[0]&s[0]) | (state[1]&s[0]);
endmodule


//=============================================
// Configuration Control
//=============================================
module ConfigurationControl(clk,select);

//---------------------------------------------
//Parameters
//---------------------------------------------
input clk;
input rst;
input trigger;
input[1:0] select; //The selection for the multiplexer
//---------------------------------------------
//Local Variables
//---------------------------------------------
wire [1:0] muxout;//The output for the mulitplexer
wire [1:0] feedback;//The feedback from the D Flip-Flops
reg  [1:0] gateout;//The output from the characteristic equations
reg  [1:0]  state; //The state of current color
//wire [1:0] s;//select for Mux
//==Create the two Flip-Flops, and plug them into the circuit
DFF A(clk, gateout, feedback) ;

//==The MUX with its inputs, the select, and its output
// Channel 0 is Feedback, The value of the previous state/current state
// Channel 1 is Single 
// Channel 2 is Double
// Channel 3 is Hilt
// S has to be  00,01,10,11

Mux4 iMux(state,select,muxout);

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

//=============================================
// Test Bench
//=============================================
module Test_FSM() ;

//---------------------------------------------
//Inputs
//---------------------------------------------
  reg clk;
 // reg rst;
  reg [1:0] select ;

 // wire out;
  
  reg [1:0] oldval;
 // reg [1:0] newval;
//  reg [1:0] state;   
 // wire [1:0] m;
//---------------------------------------------
//Declare FSM
//---------------------------------------------  
  ConfigurationControl Configuration(clk, select);
  
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
	  #3 ///Offset the Square Wave
      $display("CLK|CRT|TRG |NXT");
      $display("---+---+----+---");
	  forever
			begin
			#5				
				$display("  %b|  %b| %b| %b",clk,oldval,select,Configuration.state);
				oldval = Configuration.state;
			end	
			
   end	

   
   
   
//---------------------------------------------   
// The Input Stimulous.
// Change Configuration.
//---------------------------------------------   
   
   
  initial 
	begin
	     #3 //Offset the Square Wave
		#5 Configuration.gateout = 2'b01;
		   select=`D	;		
		#5 select=`S;
		#5 select=`H;
		#5 select=`NP;
		#5 select=`D;
		#5 select=`S	;		
		#5 select=`NP;
		#5 select=`H;
		#5 select=`S;
		#5 select=`D;				
		$finish;
	end
	
	
endmodule

 

