library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;

entity FC_layer is
     Port ( 
        clk    : in std_logic;
		rst    : in std_logic;
		start  : in std_logic;
		input  : in std_logic_vector(8191 downto 0);
        output : out std_logic_vector(3 downto 0); -- for 4 typees of objects
		done   : out std_logic
     );
     
end FC_layer;

architecture Behavioral of FC_layer is

	signal done_reg <= '0';

begin
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
--				done_reg <= '0';



			elsif start = '1' then


--				done_reg <= '1';
			else


--				done_reg <= '0';
			end if;
		end if;
	end process;

	done <= done_reg;

end Behavioral;
