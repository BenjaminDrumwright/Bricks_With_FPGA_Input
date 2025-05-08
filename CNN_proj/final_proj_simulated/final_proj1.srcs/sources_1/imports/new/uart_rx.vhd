-- uart_rx.vhd (add async reset)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        rx       : in  std_logic;
        rx_data  : out std_logic_vector(7 downto 0);
        rx_valid : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLKS_PER_BIT : integer := 868;
    type state_t is (IDLE, START, DATA, STOP, DONE);
    signal state     : state_t := IDLE;
    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others=>'0');
    signal valid_i   : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            shift_reg <= (others=>'0');
            valid_i   <= '0';

        elsif rising_edge(clk) then
            valid_i <= '0';
            case state is
                when IDLE =>
                    if rx = '0' then
                        state     <= START;
                        clk_count <= 0;
                    end if;

                when START =>
                    if clk_count = CLKS_PER_BIT/2 then
                        if rx = '0' then
                            clk_count <= 0;
                            bit_index <= 0;
                            state     <= DATA;
                        else
                            state <= IDLE;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DATA =>
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count           <= 0;
                        shift_reg(bit_index)<= rx;
                        if bit_index = 7 then
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when STOP =>
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count <= 0;
                        state     <= DONE;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DONE =>
                    valid_i <= '1';
                    state   <= IDLE;

            end case;
        end if;
    end process;

    rx_data  <= shift_reg;
    rx_valid <= valid_i;
end Behavioral;

