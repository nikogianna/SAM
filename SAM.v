module SAM (str, mode, clk, reset, msg, frame);
    input str, mode, clk, reset;
	output msg, frame;
	reg [3:0] ni;
	reg [7:0] di, capsNi;
	
	reg [2:0] n_count;
    reg [9:0] d_count, capsN_count;	
	
	reg [3:0] shifter;
	
	reg waszero, msg, rdy;
	reg [5:0] ones_count, zeros_count;
	reg [9:0] il;
	reg [7:0] mesg, msgcd, sndmsg;
	
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
            waszero     <= 1'b0;	
            ones_count  <= 6'h00;
		    zeros_count <= 6'h00;	
            il          <= 10'h001;	
            rdy         <= 1'b0;			
          end
       else if (mode)
          begin
		    ones_count  <= 6'h00;
		    zeros_count <= 6'h00;	
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
			     capsNi[capsN_count - 1] <= str;
				 capsN_count <= capsN_count - 1;
			   end
          end			 
       else if (!mode)
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
					   msgcd[il - 1]  <= (1'b1 ^ di[il -1]) | capsNi[il -1]; 
                       il           <= il - 1;
    				 end
                  else if ((ones_count < zeros_count) && (ones_count >0) && (zeros_count > 0))
                     begin
 					   mesg[il - 1] <= 1'b0;
					   msgcd[il - 1]   <= (1'b0 ^ di[il -1]) | capsNi[il -1]; 
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
       else if (!il)	
         begin 
            rdy         <= 1'b1;
			sndmsg      <= msgcd;
			il          <= 10'h008;
         end			
 		 end	

    //always @(posedge clk or negedge reset)
      // if(!reset)	
endmodule
