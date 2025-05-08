-- relu.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cnn_types.ALL;

entity relu is
    Port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;
        done   : out std_logic;
        input  : in  patch_type;
        output : out patch_type
    );
end relu;

architecture Behavioral of relu is
    type state_t is (IDLE, WORK, DONE_S);
    signal state : state_t := IDLE;
    signal temp  : patch_type := (others => (others => (others => '0')));
begin
    process(clk, rst)
    begin
        if rst = '1' then
            temp  <= (others => (others => (others => '0')));
            output<= (others => (others => (others => '0')));
            done  <= '0';
            state <= IDLE;

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        -- pass-through (no negatives expected on unsigned data)
                        temp <= input;
                        state <= WORK;
                    end if;

                when WORK =>
                    output <= temp;
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
