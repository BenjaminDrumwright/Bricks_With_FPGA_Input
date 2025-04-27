library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        tx_start    : in  std_logic;
        tx_data     : in  std_logic_vector(7 downto 0);
        tx          : out std_logic;
        tx_busy     : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is

    constant BAUD_RATE  : integer := 115200;
    constant CLOCK_FREQ : integer := 100_000_000; -- FPGA clock
    constant BAUD_TICKS : integer := CLOCK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;
    signal baud_counter : integer := 0;
    signal bit_counter : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_reg : std_logic := '1';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                baud_counter <= 0;
                bit_counter <= 0;
                shift_reg <= (others => '0');
                tx_reg <= '1';
            else
                case state is
                    when IDLE =>
                        if tx_start = '1' then
                            shift_reg <= tx_data;
                            state <= START;
                            baud_counter <= 0;
                        end if;

                    when START =>
                        if baud_counter = BAUD_TICKS then
                            baud_counter <= 0;
                            state <= DATA;
                            bit_counter <= 0;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when DATA =>
                        if baud_counter = BAUD_TICKS then
                            baud_counter <= 0;
                            if bit_counter = 7 then
                                state <= STOP;
                            else
                                bit_counter <= bit_counter + 1;
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when STOP =>
                        if baud_counter = BAUD_TICKS then
                            state <= IDLE;
                            baud_counter <= 0;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Output logic
    with state select
        tx_reg <= '0' when START,
                  shift_reg(bit_counter) when DATA,
                  '1' when STOP,
                  '1' when others;

    tx <= tx_reg;
    tx_busy <= '1' when (state /= IDLE) else '0';

end Behavioral;
