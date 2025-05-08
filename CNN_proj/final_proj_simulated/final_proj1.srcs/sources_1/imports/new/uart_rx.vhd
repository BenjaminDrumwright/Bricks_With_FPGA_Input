-- uart_rx.vhd
-- UART receiver module for 1 start bit, 8 data bits, 1 stop bit. Uses sampling at CLKS_PER_BIT to decode incoming 
-- serial stream. Emits rx_valid high for one clock cycle after a byte is received. Includes asynchronous reset.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;                     -- Asynchronous reset
        rx       : in  std_logic;                     -- UART receive line
        rx_data  : out std_logic_vector(7 downto 0);  -- Received byte
        rx_valid : out std_logic                      -- One-cycle pulse on valid byte
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLKS_PER_BIT : integer := 868;  -- For 115200 baud @ 100 MHz clock
    type state_t is (IDLE, START, DATA, STOP, DONE);

    signal state     : state_t := IDLE;
    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;  -- Samples per bit
    signal bit_index : integer range 0 to 7 := 0;               -- Bit index in byte
    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0'); -- Shift register for received bits
    signal valid_i   : std_logic := '0';                        -- Internal valid signal
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Asynchronous reset clears all internal state
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            shift_reg <= (others => '0');
            valid_i   <= '0';

        elsif rising_edge(clk) then
            valid_i <= '0';  -- Default to low; gets pulsed in DONE state

            case state is
                when IDLE =>
                    -- Wait for falling edge indicating start bit
                    if rx = '0' then
                        state     <= START;
                        clk_count <= 0;
                    end if;

                when START =>
                    -- Sample in middle of start bit
                    if clk_count = CLKS_PER_BIT/2 then
                        if rx = '0' then
                            clk_count <= 0;
                            bit_index <= 0;
                            state     <= DATA;
                        else
                            state <= IDLE;  -- False start
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DATA =>
                    -- Sample each data bit at end of bit period
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count            <= 0;
                        shift_reg(bit_index) <= rx;
                        if bit_index = 7 then
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when STOP =>
                    -- Wait one bit period for stop bit
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count <= 0;
                        state     <= DONE;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DONE =>
                    -- Output byte is valid for one clock
                    valid_i <= '1';
                    state   <= IDLE;

            end case;
        end if;
    end process;

    -- Assign outputs
    rx_data  <= shift_reg;
    rx_valid <= valid_i;
end Behavioral;

