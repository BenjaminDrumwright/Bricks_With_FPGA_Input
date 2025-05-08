-- flatten.vhd
-- Converts a 32x32 2D image patch into a 1D flattened vector of 1024 pixels. This is typically used
-- before feeding data into a fully connected layer.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.ALL;

entity flatten is
    Port (
        clk     : in std_logic;
        input   : in patch_type;     -- 2D array: 32×32 image
        output  : out flat_type      -- 1D array: 1024-element vector
    );
end flatten;

architecture Behavioral of flatten is
begin
    process(clk)
        variable idx : integer := 0; -- Tracks current flat index during traversal
    begin
        if rising_edge(clk) then
            idx := 0;
            -- Row-major flattening
            for i in 0 to 31 loop
                for j in 0 to 31 loop
                    output(idx) <= input(i,j);
                    idx := idx + 1;
                end loop;
            end loop;
        end if;
    end process;
end Behavioral;

