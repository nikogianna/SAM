module SAM_Out (clk, reset, valid, cc, mesgcd, msg, frame);

input         clk, reset, valid;  			// valid flag for valid mesgcd content
input [15: 0] mesgcd;       				// We are using 16 bits for testing purposes
input [ 9: 0] cc;           				// The number of bits to be outputted. 10 bits are used but it can be changed
output        msg, frame;

reg           frame, msg, flag;  			// flag used to control the initialization of the input register 
reg   [ 9: 0] i;           				// A register containing the number of valid bits, cc
reg   [15: 0] mesg;       				// The register containing the encoded message

always @(posedge clk or negedge reset)
 if (~reset)
   begin // 1
     flag  <= 1'b0;
     msg   <= 1'b0;
     mesg  <= 16'h0000;
   end // 1
    else if ((valid) && (~flag))			// We initialize our registers
           begin // 2
	     msg   <= mesgcd[cc - 1];			// We start outputing on msg one clock cycle after the valid termination of the norm phase
	      i    <= cc - 1;           		// using this assignment. If we can wait an extra cycle we could start outputing using a more 
				        		// orthodox method, eg.  msg   <= mesg [i - 1] when we enter the else if clause
 	      mesg <= mesgcd;           		// Here we assign the input to the register so that we can output even if the other module is in the config phase
              flag <= 1'b1;              		// We use this to only enter the initialization phase once for every encoded message
           end // 2
          else if (i && flag)
                 begin // 3
                   msg   <= mesg[i - 1];    		// Output the rest of the message
                   i     <= i - 1;
                end // 3
       else if (~|i) flag  <= 1'b0;			// The transmission is over

  always @(negedge clk or negedge reset)		// The frame output changes with the negative edge
    if (~reset) frame <= 1'b0;
     else if (valid && ~flag) frame <= 1'b1;	
      else if (i && flag) frame <= 1'b1;
       else if (~i) frame <= 1'b0;
endmodule	
