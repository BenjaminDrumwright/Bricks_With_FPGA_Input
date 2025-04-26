library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all; -- to use patch layer


entity conv_layer is
  Port (
    clk		 : in std_logic; 
    rst		 : in std_logic;
	start    : in std_logic;
	patch_in : in patch_type;
    feature  : out patch_type;
	done	 : out std_logic
   );
end conv_layer;

architecture Behavioral of conv_layer is

    -- creates a 3x3 keral to slide over the patch
    type kernel_type is array(0 to 2, 0 to 2) of signed(7 downto 0);
    constant kernel : kernel_type := (
        (to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8)),
        (to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8)),
        (to_signed(1, 8), to_signed(0, 8), to_signed(-1, 8))
    );

	signal temp_result : patch_type;
	signal done_reg    : std_logic;

    function conv_at(patch : patch_type; x, y : integer) return std_logic_vector is
        variable sum : signed(15 downto 0) := (others => '0');
    begin
        for i in 0 to 2 loop
            for j in 0 to 2 loop
                sum := sum + resize(signed(patch(x + i - 1, y + j - 1)) * kernel(i, j), 16); -- applies MAC operation to each bit
            end loop;
        end loop;
        return std_logic_vector(sum(15 downto 8)); -- truncate to 8 bits
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then --every rising edge it runs the kernal over next grid of bits
            if rst = '1' then
				temp_result <= (others => (others => (others => '0')))
				done_reg <= '0';
			elsif start = '1' then
				for i in 1 to 30 loop
					for j in 1 to 30 loop
						temp_result(i, j) <= conv_at(patch_in, i, j);
					end loop;
				end loop;
				done_reg <= '1';
			else
				done_reg <= '0';
			end if;
        end if;
    end process;
	feature <= temp_result;
	done    <= done_reg;

end Behavioral;
