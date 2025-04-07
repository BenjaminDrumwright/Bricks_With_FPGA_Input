library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;

entity flatten is
	Port ( 
		clk : in std_logic;
		input : in patch_type;
		output : out std_logic_vector(8191 downto 0)
	);
end flatten;

architecture Behavioral of flatten is

	signal flatten_out : std_logic_vector(8191 downto 0) := (others=>'0');

begin

process(input)
begin
	gen_flatten: for i in 0 to 31 generate
	for j in 0 to 31 generate
		flatten_out((i * 32 + j) * 8 + 7 downto (i * 32 + j) * 8) <= input(i)(j);
		end generate;
    end generate;
end process;

output <= flatten_out;

end Behavioral;
