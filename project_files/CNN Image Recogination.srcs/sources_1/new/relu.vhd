library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;


entity relu is
    Port (
		clk    : in std_logic;
		rst    : in std_logic;
		start  : in std_logic;
        input  : in patch_type; 
        output : out patch_type;
		done   : out std_logic;
     );
end relu;

architecture Behavioral of relu is

	signal reg_out  : patch_type;
	signal done_reg : std_logic;
	variable temp   : signed(7 downto 0);

begin
    process(clk) 
    begin 
		if rising_edge(clk) then
			if rst = '1' then
				reg_out <= (others => (others => '0'));
				done_reg <= '0';
			elsif start = '1' then
				-- loop blocks to handle each element in the patch
				for i in 0 to 31 loop
					for j in 0 to 31 loop
						temp := signed(input(i, j));  -- Type cast input from 8-bit to signed integer
						if temp < 0 then
							reg_out(i, j) <= (others => '0');  -- Set to 0 if negative
						else
							reg_out(i, j) <= std_logic_vector(temp);  -- Keep the number the same if positive
						end if;
					end loop;
				end loop;
				done_reg <= '1';
			else
				done_reg <= '0';
			end if;
		end if;
    end process;

	output <= reg_out;
	done   <= done_reg;
end Behavioral;
