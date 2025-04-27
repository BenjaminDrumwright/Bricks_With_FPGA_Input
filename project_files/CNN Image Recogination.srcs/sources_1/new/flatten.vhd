library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;

entity flatten is
    Port ( 
        input  : in patch_type;
        output : out std_logic_vector(8191 downto 0)
    );
end flatten;

architecture Behavioral of flatten is
begin
    process(input)
    begin
        for i in 0 to 31 loop
            for j in 0 to 31 loop
                output((i * 32 + j) * 8 + 7 downto (i * 32 + j) * 8) <= input(i,j);
            end loop;
        end loop;
    end process;
end Behavioral;
