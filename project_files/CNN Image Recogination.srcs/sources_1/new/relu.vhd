library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;


entity relu is
    Port (
        input : in patch_type; 
        output : out patch_type
     );
end relu;

architecture Behavioral of relu is

begin
    process(input) 
        variable temp : signed(7 downto 0);
        
    begin 
        for i in 0 to 31 loop -- nested loop to iterate through patch
            for j in 0 to 31 loop
                temp := signed(input(i, j)); -- type cast input from 8bit to signed int
                if temp < 0 then     
                    output(i, j) <= (others => '0'); -- output at that pixel is set to 0 if it negative
                else  
                    output(i, j) <= std_logic_vector(temp); -- keeps number the same if its positive
                end if;
            end loop;
        end loop;
    end process;
end Behavioral;
