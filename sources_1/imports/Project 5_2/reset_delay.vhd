library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_ARITH;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Reset_Delay IS	
    PORT (
        iCLK : IN std_logic;	
        oRESET : OUT std_logic
			);	
END Reset_Delay;


ARCHITECTURE Arch OF Reset_Delay IS
	
    SIGNAL Cont : std_logic_vector(19 DOWNTO 0):=X"00000";

BEGIN

 PROCESS
 BEGIN

	  WAIT UNTIL rising_edge (iCLK);
	  IF Cont /= X"FFFFF" THEN
	  --IF Cont /= X"0000F" THEN  --Simulation ONLY
		  Cont <= Cont + '1';	
		  oRESET <= '1';	
	  ELSE
		  oRESET <= '0';	
	  END IF;
 END PROCESS;
	
END Arch;