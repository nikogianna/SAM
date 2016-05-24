module SAM_Enc (str, mode, clk, reset, msgcd, valid, cc);
    
input          str, mode, clk, reset;
output [15: 0] msgcd;
output         valid; 
output [ 9: 0] cc; 					// cc is the number of bits of the encoded message

reg    [15: 0] msgcd ;         				// Encoded message
reg    [ 3: 0] ni;                 
reg    [15: 0] di, capsNi;  				// We are using 16 bits for testing purposes
reg    [ 2: 0] n_count;
reg    [ 9: 0] d_count, capsN_count, cc;	
reg    [ 3: 0] shifter;  				// shifter is used for d_count and capsN_count
reg    [ 5: 0] ones_count, zeros_count;  
reg    [ 9: 0] il;                       		// number of bits of d and capsN
reg    [ 1: 0] current_state, next_state; 		// states of the FSM
reg            waszero, broken;                		// waszero used as a flag for rising edge when in norm phase 
                                    			// broken used to tell when link is broken
parameter [ 1: 0] start = 0, confg = 1, norm = 2; 	// The encoding of the states

reg conf_over, valid;                       		// Flags for the end of the config phase and to tell when the saved encoded message is valid         
reg [ 15: 0] dd, cN;                           		// registers for the norm phase for d and capsN                                
	
always @(negedge clk or negedge reset)  //We use the negative edge to transition between states
 if (~reset) current_state <= start;
   else current_state <= next_state;

always @(current_state or next_state or mode or conf_over) //The FSM
  case (current_state)
    start : next_state = (mode) ? confg : start;
    confg : next_state = (~mode && ~conf_over) ? start : (conf_over && ~mode) ? norm : confg; //We only go to norm phase when config is over
    norm  : next_state = (mode) ? confg : norm;
    default : next_state = start;
  endcase
	  
	  
always @(posedge clk or negedge reset)      
  if (~reset)
    begin // 1
      cc          <= 10'h001;           
      valid       <= 1'b0;
      dd          <= 16'h0000;
      cN          <= 16'h0000;
      ni          <= 4'h0;
      di          <= 16'h00;
      capsNi      <= 16'h00;
      n_count     <= 3'h4;
      il          <= 10'h001;
      d_count     <= 10'h001;
      capsN_count <= 10'h001;
      shifter     <= 4'h8; 
      ones_count  <= 6'h00;
      zeros_count <= 6'h00;
      conf_over   <= 1'b0;
      ones_count  <= 6'h00;
      zeros_count <= 6'h00;
      waszero     <= 1'b0;		  
      broken      <= 1'b0;
    end // 1
   else 
    begin // 2
      valid <= 1'b0;              //valid will stay low except for one cycle
      if (current_state == start) //When we are in the start state we just clear everything 
        begin // 3
	  cc          <= 10'h001;
	  valid       <= 1'b0;
   	  dd          <= 16'h00;
	  cN          <= 16'h00;
          ni          <= 4'h0;
	  di          <= 16'h00;
	  capsNi      <= 16'h00;
	  n_count     <= 3'h4;
	  il          <= 10'h001;
	  d_count     <= 10'h001;
	  capsN_count <= 10'h001;
	  shifter     <= 4'h8; 
          ones_count  <= 6'h00;
	  zeros_count <= 6'h00;
          conf_over   <= 1'b0;
          waszero     <= 1'b0;		  
          broken      <= 1'b0;				
	end // 3
       else if (current_state == confg)     			// Configuration phase 
              begin // 4                           
                valid       <= 1'b0;
		if (n_count > 3'h0)                     		// While n_count is not zero, that is for 4 cycles, 
		  begin // 5                          		// give ni the transmitted n.
                    ni[n_count - 1] <= str;
		    if (str == 1'b1)                         		// If a 1 is transmitted we shift by a decreasing amount
		      begin // 6                      		// starting at shifter = 4'h8
			d_count <= d_count<<shifter; 		// shifter in action for both d_count and capsN_count
			capsN_count <= capsN_count<<shifter;
		      end // 6
			  else
			  begin 
			   d_count <= d_count; 	
			   capsN_count <= capsN_count;
			   end
		    shifter <= shifter>>1;     		// Here we shift the shifter by 1. So we can shift by a total of 
                    n_count <= n_count - 1;      		// 16 bits and everything below that. So we can count the max number of allowed bits
	            il      <= 10'h001;          		// We instantiate il every time we enter the config phase since it           
		    cc      <= 10'h001;          		// might have been reduced to 0 from the previous norm phase
                  end // 5
		 else if (d_count > 10'h000)
		        begin // 7
			  di[d_count - 1] <= str;     		// We receive the d key and save it in di
			  d_count         <= d_count - 1;
			end // 7
		       else if (capsN_count > 10'h000)           		// We do the same for N and capsNi
			      begin // 8
			        if (capsN_count == 1)     	// Here we know we have reached the end of the config phase
				  begin // 9                    // so we raise the conf_over flag and give cc and il their 
				    il        <= il<<ni;  	// final values for this configuration
				    cc        <= cc<<ni;
				    conf_over <= 1'b1;
                                  end

                    else begin 
					il        <= 10'h001;  	// final values for this configuration
				    cc        <= 10'h001;
                    end					// 9					 
			        capsNi[capsN_count - 1] <= str;
				capsN_count             <= capsN_count - 1;
			      end // 8
              end // 4
			 // end
	     else if ((current_state == norm) && (il))  //Normal phase
                    begin // 9
	              valid <= 1'b0;
                      if (conf_over)
		        begin // 10
			  valid       <= 1'b0; 
			  dd          <= di;        //We use an extra set of registers for d and N
			  cN          <= capsNi;    //so that we can clear the di and capsNi registers
		          ni          <= 4'h0;      //for the next config phase
		          di          <= 16'h00;
		          capsNi      <= 16'h00;
		          n_count     <= 3'h4;
		          d_count     <= 10'h001;
		          capsN_count <= 10'h001;
		          shifter     <= 4'h8; 
			  conf_over   <= 1'b0;	
                          ones_count  <= 6'h00;
		          zeros_count <= 6'h00;				
			end // 10
                else
                begin
  				 if (waszero && str)  									// We only start to count valid ones and zeros if we have seen any number 
		        begin // 11                             						// of zeros, essentially detecting a rising edge
                          waszero     <= 1'b0;									// Return to zero since we are in the aces area of the next bit
		          if (broken || ((ones_count + zeros_count) < 10) || ((ones_count + zeros_count) > 60)) // if we have a broken link delete the count
                            begin // 12
			      ones_count  <= 6'h00;
			      zeros_count <= 6'h00;
			    end // 12
                         else if ((ones_count >= zeros_count) && (ones_count > 0) && (zeros_count > 0))		// If the bit is valid give it its value
                            begin // 13
		              if (il == 10'h001) valid <= 1'b1;
                      else valid <= 1'b0;					  // If this is the end of the expected string raise the valid flag
                              msgcd[il - 1]        <= (1'b1 ^ dd[il -1]) | cN[il -1]; 				// Here the encoding takes place
		              il                   <= il - 1;
    		            end // 13
                           else if ((ones_count < zeros_count) && (ones_count >0) && (zeros_count > 0))
                                  begin // 14
			            if (il == 10'h001) valid <= 1'b1;
                        else valid <= 1'b0;							
			            msgcd[il - 1]        <= (1'b0 ^ dd[il -1]) | cN[il -1]; 
			            il                   <= il - 1;
			          end // 14			  
                          ones_count  <= 6'h01;  								// Since we have just entered a new aces area we already have an ace
			  zeros_count <= 6'h00;
		        end // 11
				
             	       else if (str && ~broken) 
			      begin // 15
			        ones_count <= ones_count + 1;
			        if (ones_count > 60) broken <= 1'b1; 
                    else broken <= 1'b0;					// We use this so that we don't count to infinity 
                              end // 15
			     else if (~str && ~broken)
				    begin // 16
				      waszero <= 1'b1;               //We raise the waszero flag since we have entered a zero area
				      zeros_count <= zeros_count + 1;
				      if (zeros_count > 60) broken <= 1'b1;
					  else broken <= 1'b0;
				    end 
					end// 16
 	end // 9	
    end // 2 

endmodule
