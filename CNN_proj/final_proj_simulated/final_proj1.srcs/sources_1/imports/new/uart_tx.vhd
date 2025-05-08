-- uart_tx.vhd (add async reset)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        tx_start : in  std_logic;
        tx_data  : in  std_logic_vector(7 downto 0);
        tx       : out std_logic;
        tx_busy  : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLKS_PER_BIT : integer := 868;
    type state_t is (IDLE, START, DATA, STOP);
    signal state     : state_t := IDLE;
    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others=>'0');
    signal tx_reg    : std_logic := '1';
begin
    tx       <= tx_reg;
    tx_busy  <= '1' when state /= IDLE else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_reg    <= '1';

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_reg <= '1';
                    if tx_start = '1' then
                        shift_reg<= tx_data;
                        state    <= START;
                        clk_count<= 0;
                    end if;

                when START =>
                    tx_reg <= '0';
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count <= 0;
                        bit_index <= 0;
                        state     <= DATA;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DATA =>
                    tx_reg <= shift_reg(bit_index);
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count <= 0;
                        if bit_index = 7 then
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when STOP =>
                    tx_reg <= '1';
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count <= 0;
                        state     <= IDLE;
                    else
                        clk_count <= clk_count + 1;
                    end if;

            end case;
        end if;
    end process;
end Behavioral;

