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
        done   : out std_logic
    );
end relu;

architecture Behavioral of relu is

    signal reg_out  : patch_type;
    signal done_reg : std_logic := '0';

    signal i_reg, j_reg : integer range 0 to 31 := 0;
    signal working      : std_logic := '0';

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                for i in 0 to 31 loop
                    for j in 0 to 31 loop
                        reg_out(i,j) <= (others => '0');
                    end loop;
                end loop;
                done_reg <= '0';
                working <= '0';
                i_reg <= 0;
                j_reg <= 0;

            elsif start = '1' then
                working <= '1';
                done_reg <= '0';

            elsif working = '1' then
                -- Apply ReLU on one pixel per clock
                if signed(input(i_reg, j_reg)) < 0 then
                    reg_out(i_reg, j_reg) <= (others => '0');
                else
                    reg_out(i_reg, j_reg) <= input(i_reg, j_reg);
                end if;

                -- Update indices
                if j_reg < 31 then
                    j_reg <= j_reg + 1;
                else
                    j_reg <= 0;
                    if i_reg < 31 then
                        i_reg <= i_reg + 1;
                    else
                        i_reg <= 0;
                        working <= '0';
                        done_reg <= '1'; -- Finished ReLU
                    end if;
                end if;
            end if;
        end if;
    end process;

    output <= reg_out;
    done <= done_reg;

end Behavioral;
