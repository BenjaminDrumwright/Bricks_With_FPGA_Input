-- conv_layer.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.ALL;

entity conv_layer is
    Port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;
        done   : out std_logic;
        input  : in  patch_type;
        output : out patch_type
    );
end conv_layer;

architecture Behavioral of conv_layer is
    type sum_mat_t is array (0 to 31, 0 to 31) of unsigned(11 downto 0);
    signal sum_mat    : sum_mat_t := (others => (others => (others => '0')));
    signal temp_patch : patch_type := (others => (others => (others => '0')));
    type state_t is (IDLE, ACCUM, SCALE, DONE_S);
    signal state : state_t := IDLE;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            sum_mat    <= (others => (others => (others => '0')));
            temp_patch <= (others => (others => (others => '0')));
            output     <= (others => (others => (others => '0')));
            done       <= '0';
            state      <= IDLE;

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        -- Accumulate 3×3 sum for interior pixels
                        for i in 1 to 30 loop
                            for j in 1 to 30 loop
                                sum_mat(i,j) <=
                                    resize(unsigned(input(i-1,j-1)),12) +
                                    resize(unsigned(input(i-1,j  )),12) +
                                    resize(unsigned(input(i-1,j+1)),12) +
                                    resize(unsigned(input(i  ,j-1)),12) +
                                    resize(unsigned(input(i  ,j  )),12) +
                                    resize(unsigned(input(i  ,j+1)),12) +
                                    resize(unsigned(input(i+1,j-1)),12) +
                                    resize(unsigned(input(i+1,j  )),12) +
                                    resize(unsigned(input(i+1,j+1)),12);
                            end loop;
                        end loop;
                        state <= ACCUM;
                    end if;

                when ACCUM =>
                    -- Average (divide by 9) and truncate to 8 bits
                    for i in 1 to 30 loop
                        for j in 1 to 30 loop
                            temp_patch(i,j) <=
                                std_logic_vector(resize(sum_mat(i,j) / 9, 8));
                        end loop;
                    end loop;
                    -- Zero borders
                    for k in 0 to 31 loop
                        temp_patch(0, k)  <= (others => '0');
                        temp_patch(31,k)  <= (others => '0');
                        temp_patch(k, 0)  <= (others => '0');
                        temp_patch(k,31)  <= (others => '0');
                    end loop;
                    state <= SCALE;

                when SCALE =>
                    output <= temp_patch;
                    done   <= '1';
                    state  <= DONE_S;

                when DONE_S =>
                    if start = '0' then
                        done  <= '0';
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
