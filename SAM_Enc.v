module SAM_Enc (str, mode, clk, reset, mesg);
    
input str, mode, clk, reset;
output mesg;
reg [3:0] ni;
reg [7:0] di, capsNi;

reg [2:0] n_count;
reg [9:0] d_count, capsN_count;	
	
reg [3:0] shifter;
	
reg waszero;
reg [5:0] ones_count, zeros_count;
reg [9:0] il;//, ils;
reg [7:0] mesg, msgcd, sndmsg;
	
reg [1:0] current_state, next_state;

parameter [1:0] start = 0, confg = 1, norm = 2;
reg conf_over;

	
	always @(negedge clk or negedge reset)
     if (!reset) current_state <= start;
     else current_state <= next_state;
	 

	always @(mode or current_state)
	  case (current_state)
	    start : next_state = (mode) ? confg : start;
		confg : next_state = ((!mode) && (!conf_over)) ? start : ((conf_over) && (!mode)) ? norm : confg;
        norm : next_state = (mode) ? start : norm; 		
	    default next_state = start;
	  endcase
	  
	  
	always @(posedge clk or negedge reset)
	  if (!reset)
	    begin
          ni          <= 4'h0;
		  di          <= 8'h00;
		  capsNi      <= 8'h00;
		  n_count     <= 3'h4;
		  d_count     <= 10'h001;
		  capsN_count <= 10'h001;
		  shifter     <= 4'h8; 
          ones_count  <= 6'h00;
		  zeros_count <= 6'h00;
          conf_over   <= 1'b0;		  
		end
	  else if (current_state == confg)
          begin
		    //ones_count  <= 6'h00;
		    //zeros_count <= 6'h00;	
            if (n_count)
			  begin
                ni[n_count - 1] <= str;
				 if (str)
				  begin
				   d_count <= d_count << shifter;
				   capsN_count <= capsN_count << shifter;
				   il          <= il << shifter;
				  end
				shifter <= shifter >> 1;
                n_count <= n_count - 1;
              end
			else if (d_count)
			   begin
			     di[d_count - 1] <= str;
				 d_count <= d_count - 1;
			   end
			else if (capsN_count)
			   begin 
			     if (!(capsN_count - 1)) conf_over <= 1'b1; 
			     capsNi[capsN_count - 1] <= str;
				 capsN_count <= capsN_count - 1;
			   end
			//else conf_over <= 1'b1;
		  end


    always @(negedge clk or negedge reset)
	  if (!reset)
	    begin
		  il          <= 10'h001; 
          ones_count  <= 6'h00;
		  zeros_count <= 6'h00;
          waszero     <= 1'b0;		  
		end
	  else if (current_state == norm)
        begin
		   if (il)
		     begin
              if ((waszero == 1'b1) && (str == 1'b1))
			    begin
				  waszero     <= 1'b0;
				  
				  if (((ones_count + zeros_count) < 10) || ((ones_count + zeros_count) > 60))
				     begin
					    ones_count  <= 6'h00;
						zeros_count <= 6'h00;
					 end
                  
				  if ((ones_count >= zeros_count) && (ones_count > 0) && (zeros_count > 0))
                     begin 
					   mesg[il - 1] <= 1'b1;
					   //msgcd[il - 1]  <= (1'b1 ^ di[il -1]) | capsNi[il -1]; 
                       il           <= il - 1;
    				 end
                  else if ((ones_count < zeros_count) && (ones_count >0) && (zeros_count > 0))
                     begin
 					   mesg[il - 1] <= 1'b0;
					   //msgcd[il - 1]   <= (1'b0 ^ di[il -1]) | capsNi[il -1]; 
 					   il           <= il - 1;
					 end			  
				
				ones_count  <= 6'h01;
				zeros_count <= 6'h00;
				end
             				
			  else if (str == 1'b1)
				begin
				  ones_count <= ones_count + 1;
                end
			  else if (str == 1'b0)
				begin
				  waszero <= 1'b1;
				  zeros_count <= zeros_count + 1;
				end
            end 	
        end
		
endmodule
