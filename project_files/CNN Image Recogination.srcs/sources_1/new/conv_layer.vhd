library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all; -- patch_type

entity conv_layer is
  Port (
    clk      : in std_logic; 
    rst      : in std_logic;
    start    : in std_logic;
    patch_in : in patch_type;
    feature  : out patch_type;
    done     : out std_logic
  );
end conv_layer;

architecture Behavioral of conv_layer is

    -- 3x3 Kernel
    type kernel_type is array(0 to 2, 0 to 2) of signed(7 downto 0);
    constant kernel : kernel_type := (
        (to_signed(1,8), to_signed(0,8), to_signed(-1,8)),
        (to_signed(1,8), to_signed(0,8), to_signed(-1,8)),
        (to_signed(1,8), to_signed(0,8), to_signed(-1,8))
    );

    signal temp_result : patch_type;
    signal done_reg    : std_logic := '0';

    signal i_reg, j_reg : integer range 0 to 31 := 1; -- start at 1 for valid conv

    function conv_at(patch : patch_type; x, y : integer) return std_logic_vector is
        variable sum : signed(15 downto 0) := (others => '0');
    begin
        for i in 0 to 2 loop
            for j in 0 to 2 loop
                sum := sum + resize(
                    signed(patch(x + i - 1, y + j - 1)) * kernel(i, j),
                    16
                );
            end loop;
        end loop;
        return std_logic_vector(sum(15 downto 8)); -- keep 8 bits
    end function;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Reset everything
                for i in 0 to 31 loop
                    for j in 0 to 31 loop
                        temp_result(i,j) <= (others => '0');
                    end loop;
                end loop;
                done_reg <= '0';
                i_reg <= 1;
                j_reg <= 1;

            elsif start = '1' then
                -- Perform convolution one pixel per clock cycle
                temp_result(i_reg, j_reg) <= conv_at(patch_in, i_reg, j_reg);

                -- Update indices
                if j_reg < 30 then
                    j_reg <= j_reg + 1;
                else
                    j_reg <= 1;
                    if i_reg < 30 then
                        i_reg <= i_reg + 1;
                    else
                        i_reg <= 1;
                        done_reg <= '1'; -- Finished convolution
                    end if;
                end if;

            else
                done_reg <= '0'; -- Idle state
            end if;
        end if;
    end process;

    feature <= temp_result;
    done <= done_reg;

end Behavioral;
