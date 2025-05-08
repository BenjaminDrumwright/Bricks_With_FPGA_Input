library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.ALL;

entity flatten is
    Port (
        clk     : in std_logic;
        input   : in patch_type;
        output  : out flat_type
    );
end flatten;

architecture Behavioral of flatten is
begin
    process(clk)
        variable idx : integer := 0;
    begin
        if rising_edge(clk) then
            idx := 0;
            for i in 0 to 31 loop
                for j in 0 to 31 loop
                    output(idx) <= input(i,j);
                    idx := idx + 1;
                end loop;
            end loop;
        end if;
    end process;
end Behavioral;
