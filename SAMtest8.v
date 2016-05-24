// Created by H. T. Vergos 
// Revision 1.8 

module SAMtest ();
  reg  str;
  reg  mode;
  reg  clk;
  reg  reset;
  wire msg;
  wire frame;
  integer seed;           // Seed for random variables  
  integer idle_cycles;    // Configuration starts after some random idle_cycles  
  integer key_length;     // This needs to be an integer in order for the Simulator to use it in
                          // computations. This is a limit of the specific simulator and NOT of Verilog.

  reg  [2:0] counter;     // Counts the clock cycles that n is loaded in SAM.
  reg  [9:0] counter2;    // Counts the bits of d
  reg  [9:0] counter3;    // Counts the bits of capsN
                          // (note that capsN is used instead of N) since Verilog is not a case sensitive language
  reg  [3:0] n;
  reg  [7:0] d;           // Indicative for this example values used. They are not necessary though when 3 is assigned in n
  reg  [7:0] capsN;       // Provided here for future revisions

  reg  [4:0] counterones; // Holds the clock cycles that str will be HIGH in a bit
  reg  [4:0] counterzeros;// Holds the clock cycles that str will be LOW in a bit
  reg  [7:0] sent;        // Holds the message sent to SAM
                          // You may use this along with capsN and d, in order to compute the correct output of SAM
                          // In this way you only need to extend this code by a few lines to get an automatic
                          // verification that SAM operates correctly.
  reg        state;       // Used to distinguish between configuration and message state
                          // After the configuration is over, str should be driven to 0 before the message is sent.
                          // However, the last bit of the configuration may be 1, therefore you 've got to devise a
                          // mechanism to sent str to 0 at least for 1 clock cycle.
  integer i;
  integer sx;  // Holds number of generated bits

SAM CUT (str, mode, clk, reset, msg, frame); 	// Once you have described SAM you need to uncomment this
                                                // You may need to change that if you have arranged I/Os in a different way
                                             	// or if you have named your module diferrently

initial                    			// At initialisation all signals are inactive.
  begin                    			// SAM should therefore get in some weird DECODE stage 
    clk        = 1'b0;
    str        = 1'b1;
    reset      = 1'b1;
    n          = 4'h3;    			// These are sample values. However if your circuit is configured
    counter    = 3'h4; 				// correctly for these values you get a mark > 5.
    counter2   = 10'h008;
    counter3   = 10'h008;
    key_length = 8;
 #5 mode       = 1'b0;
    i          = 0;
	sx         = 0;
    reset      = 1'b0;
#4  reset      = 1'b1;
  end

always #20 clk = !clk; // Our clock ticks here

// Configuration Starts Here
// Wait for a random (0 - 15) number of clock cycles
// Also assign random values to d and capsN
// Note that random returns an integer of 15 bits.

initial
  begin
    seed        = $random(32434);
    idle_cycles = $random(seed - 21) % 16;
    d           = 8'hFF;//$random(seed +3);
    capsN       = 8'hFF;
  end

// At next positive edge set MODE to 1. Turn it back to 0 once n, d and capsN have been sent.

initial
  begin
    # (40*idle_cycles +21)        mode = 1'b1;
                                  state = 1'b1; // Configuration state indicated.
    # (40*(n+(2*key_length)+1)+5) mode = 1'b0;  // Extra cycle required for handling the two unmodelled edges
                                                // that is, the one before transmission of n and
                                                // the one after the last bit of capsN
    # (10*key_length) i = 9;                    // After the end of configuration, we let some time pass before the
                                                // first bit of the first message appears. Note that i is initialized to 9
                                                // since you need the start of the (n+1) bit to be sure that a message of n
                                                // bits has arrived in good order.
      counterones = 5'h0;
      counterzeros = 5'h0;
	  
	// Configuration state indicated.
    # 11000  mode = 1'b0;  // Extra cycle required for handling the two unmodelled edges
                                                // that is, the one before transmission of n and
                                                // the one after the last bit of capsN
    # 11100 i = 9;
            sx = 1;	// After the end of configuration, we let some time pass before the
                                                // first bit of the first message appears. Note that i is initialized to 9
                                                // since you need the start of the (n+1) bit to be sure that a message of n
                                                // bits has arrived in good ord
  end


 // At every next negative edge the value of n is presented on the str line.
 // After n is done d and capsN follow. I have assumed MSB appears first.

always @(negedge clk)
    if (mode)  						// n appears just after mode goes high
      begin
        if (counter)
          begin
            str     <= n[counter-1];
            counter <= counter - 1;
          end
        else if (counter2) 				// time for d
               begin
                 str      <= d[counter2-1];
                 counter2 <= counter2 - 1;
                end
             else if (counter3) 			// time for capsN
                    begin
                      str      <= capsN[counter3-1];
                      counter3 <= counter3 - 1;
                     end
      end
 // That completes our configuration phase. By now your SAM should have its registers keeping n, d, N
 // configured. You may want to add after this code straight comparisons between the random values
 // and those configured. This means that you may want to alter your FSM, in a way that once the config phase is
 // over the configured values appear at new outputs that you would like this testbench to have access to.
    
 // Str must be driven to 0 before a message starts. Therefore we have to at least insert an idle cycle
 // between the last configuration bit (that may be 1) and the start of an new message (indicated by a rising edge)

     else if (state)
            begin
              state <= 1'b0;
              str <= 1'b0;
            end
           else

// Message starts hereafter.

      begin
        if ((i) && (!sx))                                       // We only provide for a sample message. You may want to change this
                                                    // if you feel the need for more. 
          begin 
            if ( (!counterones) && (!counterzeros) )// Previous bit complete
              begin
                counterones  = 5 + 5;//$random%25;      // Generate the 1 duration between 5 and 29 cycles
                counterzeros = 5 + 12;//$random%24;      // Generate the 0 duration between 5 and 28 cycles
                                                    // Note that this provides only with CORRECT messages as far as their
                                                    // duration is concerned but does not exclude that a bit is equal
                                                    // times at 1 and at 0. To overcome this you may define 
                                                    // counterzeros as a random disposal of the counterones values.
                                                    // You may want to make your own changes for testing your fault
                                                    // handling capabilities as well.
                if (counterones > counterzeros)     // Determine what bit will be created and store it.
                  sent[i-2] <= 1'b1;    
                else sent[i-2] <= 1'b0;
                i <= i-1;
              end
          end
		  else if ((sx) && (i))
		   begin 
		    if ( (!counterones) && (!counterzeros) )// Previous bit complete
              begin
                counterones  = 5 + 15;//$random%25;      // Generate the 1 duration between 5 and 29 cycles
                counterzeros = 5 + 7;//$random%24;      // Generate the 0 duration between 5 and 28 cycles
                                                    // Note that this provides only with CORRECT messages as far as their
                                                    // duration is concerned but does not exclude that a bit is equal
                                                    // times at 1 and at 0. To overcome this you may define 
                                                    // counterzeros as a random disposal of the counterones values.
                                                    // You may want to make your own changes for testing your fault
                                                    // handling capabilities as well.
                if (counterones > counterzeros)     // Determine what bit will be created and store it.
                  sent[i-2] <= 1'b1;    
                else sent[i-2] <= 1'b0;
                i <= i-1;
              end
          end
         //else $stop();
      end


// Actual message generation starts hereafter

always @(posedge clk)
  begin
    if (counterones) 				          // At 1 for counterones clock cycles
      begin
        str <= 1'b1;
        counterones <= counterones - 1;
      end
    else if (counterzeros) 				    // At 0 for counterzeros clock cycles
           begin
             str <= 1'b0;
             counterzeros <= counterzeros - 1;
           end
  end

endmodule
