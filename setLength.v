
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

module checkLength(bladeConfig, maxL, maxR, floatL, floatR, hiltLength, lengthL, lengthR, lengthH);

    input [1:0] bladeConfig;
    input [15:0] maxL, maxR, floatL, floatR, hiltLength;
    output [15:0] lengthL, lengthR, lengthH;

    reg signed [15:0] lengthL, lengthR, lengthH;

    always @ (bladeConfig, maxL, maxR, floatL, floatR, hiltLength, lengthL, lengthR, lengthH)
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
			lengthH = 16'sb0000000000000000;
			$display("Your single blade has a length of %2d.%02d meters.", lengthL, lengthR);
		end
		else if(bladeConfig == 16'b0000000000000010)
		begin
			lengthH = 16'sb0000000000000000;
			$display("Both of your blades have a length of %2d.%02d meters.", lengthL, lengthR);
		end
		else if(bladeConfig == 16'b0000000000000011)
		begin
			lengthH = 16'sb0000000000001010;
			$display("Your single blade has a length of %2d.%02d meters and your hilts have a set size of %02d cm.", lengthL, lengthR, lengthH);
		end

	    end
	end

endmodule

//---------------------------------------------------------------------
// Module for setting the length of the blade
//---------------------------------------------------------------------

module SetLength(clk, rst, maxL, maxR, floatL, floatR, hiltLength, bladeConfig, outL, outR, outH);

    input clk, rst;
    input [1:0] bladeConfig;
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

    checkLength newLength(bladeConfig, maxL, maxR, floatL, floatR, hiltLength, setL, setR, setH); 

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

    //Declare the inputs.

    parameter n = 16;	//5 bits wide

    reg clk, rst; 
    reg [n-1:0] maxL = 16'sb0000000000000001;  //Max of 1 meter on the left of decimal
    reg [n-1:0] maxR = 16'sb0000000001100011;  //Max of 99 cm on the right of decimal
    reg signed [n-1:0] floatL, floatR, hiltLength;
    reg [1:0] bladeConfig = 2'b10;

    //Declare the outputs.

    wire signed [n-1:0] outLeft, outRight, outHilt;

    //Initilize the saturation counter.

    SetLength bladeLength(clk, rst, maxL, maxR, floatL, floatR, hiltLength, bladeConfig, outLeft, outRight, outHilt);

    // Display the contents of the saturation counter for every cycle of 10.

      initial begin
	 //Start the clk

         clk = 1;
	 #5 clk = 0;

	 //Display the header for the table

	 $display(" CLK | RST | Max Length | Desired Length | Blade Length | Hilt Length | Blade Config");
	 $display("-----+-----+------------+----------------+--------------+-------------|-------------");

         forever begin
	    //Display the output in a table

	    $display("  %b | %b | %2d.%02d m |  %2d.%02d m | %2d.%02d m | 0.%02d | %2d", clk, rst, maxL, maxR, floatL, floatR, outLeft, outRight, outHilt, bladeConfig);

            #5 clk = 1;

	    $display("  %b | %b | %2d.%02d m |  %2d.%02d m | %2d.%02d m | 0.%02d | %2d", clk, rst, maxL, maxR, floatL, floatR, outLeft, outRight, outHilt, bladeConfig);

            #5 clk = 0;

       end 

    end

    //Set the stimulus for the saturation counter.

    initial begin 

        // Test loads
	
	#30 rst = 1; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b00;  //Set length to -1.00 m
	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b01; //Set length to -1.00 m
	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b10; //Set length to -1.00 m
	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb0000000000000000; bladeConfig = 2'b11; //Set length to -1.00 m

	#50

	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b01; //Set length to 0.-01 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b10; //Set length to 0.-01 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b11; //Set length to 0.-01 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb1111111111111111; bladeConfig = 2'b00; //Set length to 0.-01 m

	#50

	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b01; //Set length to -1.-01 m
	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b10; //Set length to -1.-01 m
	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b11; //Set length to -1.-01 m
	#30 rst = 0; floatL = 16'sb1111111111111111; floatR = 16'sb1111111111111111; bladeConfig = 2'b00; //Set length to -1.-01 m

	#50

        #30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b01; //Set length to 0.00 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b10; //Set length to 0.00 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b11; //Set length to 0.00 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000000; bladeConfig = 2'b00; //Set length to 0.00 m

	#50

        #30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b01; //Set length to 0.23 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b10; //Set length to 0.23 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b11; //Set length to 0.23 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000000011; bladeConfig = 2'b00; //Set length to 0.23 m

	#50

        #30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b01; //Set length to 0.50 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b10; //Set length to 0.50 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b11; //Set length to 0.50 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000000110010; bladeConfig = 2'b00; //Set length to 0.50 m

	#50	

	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b01; //Set length to 0.100 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b10; //Set length to 0.100 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b11; //Set length to 0.100 m
	#30 rst = 0; floatL = 16'sb0000000000000000; floatR = 16'sb0000000001100100; bladeConfig = 2'b00; //Set length to 0.100 m

	#50

        #30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; bladeConfig = 2'b01; //Set length to 1.00 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; bladeConfig = 2'b10; //Set length to 1.00 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; bladeConfig = 2'b11; //Set length to 1.00 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb0000000000000000; bladeConfig = 2'b00; //Set length to 1.00 m

	#50 

	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b01; //Set length to 1.01 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b10; //Set length to 1.01 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b11; //Set length to 1.01 m
	#30 rst = 0; floatL = 16'sb000000000000001; floatR = 16'sb000000000000001; bladeConfig = 2'b00; //Set length to 1.01 m

 
       //Finish the program

       $finish;

    end 

endmodule //Close the testbench module