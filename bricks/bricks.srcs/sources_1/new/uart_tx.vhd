-- uart_tx.vhd
-- This module serializes data from paddle_controllers and sends over uart bit by bit
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        tx_start : in  std_logic; -- start signal to start transmitting
        tx_data  : in  std_logic_vector(7 downto 0); -- data to be transmitted (hex value)
        tx       : out std_logic; -- transmitted data output
        tx_busy  : out std_logic -- if uart is busy sending data
    );
end uart_tx;

architecture Behavioral of uart_tx is
    constant BAUD_DIV : integer := 868; -- buad rate divider for 11520 baud rate
    signal baud_cnt   : integer range 0 to BAUD_DIV := 0;  -- buad rate counter
    signal bit_cnt    : integer range 0 to 9 := 0; -- bit counter for each transmitted byte
    signal shift_reg  : std_logic_vector(9 downto 0) := (others => '1'); -- shift register for serial transmission
    signal sending    : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- clear data if reset is high
            if rst = '1' then
                tx <= '1'; -- set high to show idle state
                sending <= '0';
                baud_cnt <= 0;
                bit_cnt <= 0;
                tx_busy <= '0';
            -- Start transmitting data if the uart is clear
            elsif tx_start = '1' and sending = '0' then
                -- Frame = 1 stop bit + 8 data + 1 start bit (LSB first)
                shift_reg <= '1' & tx_data & '0';  -- stop | data | start
                sending <= '1'; 
                tx_busy <= '1';
                baud_cnt <= 0;
                bit_cnt <= 0;
            -- if uart is busy, put data in shift register
            elsif sending = '1' then
                if baud_cnt = BAUD_DIV then
                    tx <= shift_reg(0);
                    shift_reg <= '1' & shift_reg(9 downto 1);
                    baud_cnt <= 0;
                    bit_cnt <= bit_cnt + 1;
                    -- data transmission complete, open uart again
                    if bit_cnt = 9 then
                        sending <= '0';
                        tx_busy <= '0';
                    end if;
                else
                    baud_cnt <= baud_cnt + 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;

