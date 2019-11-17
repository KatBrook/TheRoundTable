/*
Filename     powerHandler.v
Date         11-07-19
Author       Matthew Rachele
Email        mor170030@utdallas.edu
Course       CS4341.001
Version      1.0
Copyright    2019, All Rights Reserved

Description  

SOFTWARE:    Icarus Verilog - iverilog

SOURCE:      
[1]      S. Williams, “Icarus Verilog,” Icarus Verilog. [Online]. 
         Available: http://iverilog.icarus.com/. [Accessed: 2-Sep-2019].

*/


//D Flip-flop-----------------------------------------------------------
module DFF(clk, in, out);
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
module PowerSetting(clk, powIn, powOut);
    input [2:0] powIn; //training 001, dueling 010, or bulkheads 100
    input clk;
    output [2:0] powOut;
    wire [2:0] powOut;

    DFF A0 (clk, powIn[0], powOut[0]);
    DFF A1 (clk, powIn[1], powOut[1]);
    DFF A2 (clk, powIn[2], powOut[2]);
 
endmodule
//----------------------------------------------------------------------



//----------------------------------------------------------------------
module testbench();

    //Registers to hold var data
    reg [4:0] i; //loop control for 16 rows of the truth table
    reg  clk;
    reg  rst;
    reg  [2:0] in;
    
    //Wires to hold function results
    wire [2:0] out;
    
    //Instantiate modules - function automatically
    PowerSetting zap(clk, in, out);

    initial begin
	    forever begin
			#5 
			clk = 0 ;
			#5
			clk = 1 ;
		end
    end	

    //Begin running system
    initial begin 
        in = {3'b100};

        #15

        $display ("Power Setting - %3b", out);

        if(out == {3'b001}) begin
            $display ("Power Setting - Training");
        end else if (out == {3'b010}) begin
            $display ("Power Setting - Dueling");
        end else if (out == {3'b100}) begin
            $display ("Power Setting - Bulkhead");
        end else begin
            $display ("Power Setting - Error - Bad Input");
        end


        #15

        in = {3'b010};

        #15

        $display ("");
        $display ("Power Setting - %3b", out);

       if(out == {3'b001}) begin
            $display ("Power Setting - Training");
        end else if (out == {3'b010}) begin
            $display ("Power Setting - Dueling");
        end else if (out == {3'b100}) begin
            $display ("Power Setting - Bulkhead");
        end else begin
            $display ("Power Setting - Error - Bad Input");
        end

        #15

        in = {3'b001};

        #15

        $display ("");
        $display ("Power Setting - %3b", out);

       if(out == {3'b001}) begin
            $display ("Power Setting - Training");
        end else if (out == {3'b010}) begin
            $display ("Power Setting - Dueling");
        end else if (out == {3'b100}) begin
            $display ("Power Setting - Bulkhead");
        end else begin
            $display ("Power Setting - Error - Bad Input");
        end


    
        #10       //Delay to allow time for computation
        $finish;  //Finishes/Stops the running code
    end  
endmodule //Close the testbench module
//----------------------------------------------------------------------
