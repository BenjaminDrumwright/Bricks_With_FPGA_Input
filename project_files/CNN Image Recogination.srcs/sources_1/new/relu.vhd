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
         -- loop blocks to handle each element in the patch
         for i in 0 to 31 loop
            for j in 0 to 31 loop
                temp := signed(input(i, j));  -- Type cast input from 8-bit to signed integer
                if temp < 0 then
                    output(i, j) <= (others => '0');  -- Set to 0 if negative
                else
                    output(i, j) <= std_logic_vector(temp);  -- Keep the number the same if positive
                end if;
            end loop;
        end loop;
    end process;
end Behavioral;
