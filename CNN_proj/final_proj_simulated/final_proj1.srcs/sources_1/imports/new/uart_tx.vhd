-- uart_tx.vhd
-- UART transmitter module. Sends one byte over serial line using 1 start bit, 8 data bits, and 1 stop bit 
-- at 115200 baud (with 100 MHz clk). tx_start triggers transmission; tx_busy is high during transmission.
-- Includes asynchronous reset.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;                      -- Asynchronous reset
        tx_start : in  std_logic;                      -- Pulse to start transmission
        tx_data  : in  std_logic_vector(7 downto 0);   -- Byte to transmit
        tx       : out std_logic;                      -- UART TX line
        tx_busy  : out std_logic                       -- High while transmitting
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLKS_PER_BIT : integer := 868;  -- For 115200 baud @ 100 MHz
    type state_t is (IDLE, START, DATA, STOP);

    signal state     : state_t := IDLE;
    signal clk_count : integer range 0 to CLKS_PER_BIT-1 := 0;  -- Clock cycles per bit
    signal bit_index : integer range 0 to 7 := 0;               -- Bit index for data bits
    signal shift_reg : std_logic_vector(7 downto 0) := (others=>'0'); -- Shift register for data
    signal tx_reg    : std_logic := '1';                        -- Output TX bit register
begin
    -- Drive outputs
    tx      <= tx_reg;
    tx_busy <= '1' when state /= IDLE else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            -- Asynchronous reset
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_reg    <= '1';

        elsif rising_edge(clk) then
            case state is

                when IDLE =>
                    tx_reg <= '1';  -- Line idle state is HIGH
                    if tx_start = '1' then
                        -- Load data and begin transmission
                        shift_reg <= tx_data;
                        state     <= START;
                        clk_count <= 0;
                    end if;

                when START =>
                    tx_reg <= '0';  -- Send start bit (LOW)
                    if clk_count = CLKS_PER_BIT-1 then
                        clk_count <= 0;
                        bit_index <= 0;
                        state     <= DATA;
                    else
                        clk_count <= clk_count + 1;
                    end if;

                when DATA =>
                    tx_reg <= shift_reg(bit_index);  -- Transmit current data bit
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
                    tx_reg <= '1';  -- Send stop bit (HIGH)
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


