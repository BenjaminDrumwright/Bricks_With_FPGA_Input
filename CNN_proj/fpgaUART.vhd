library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart_receiver is
    Port ( clk        : in  STD_LOGIC;
           rst        : in  STD_LOGIC;
           rx         : in  STD_LOGIC;  -- UART RX (receive line)
           data_out   : out STD_LOGIC_VECTOR(7 downto 0); -- received byte
           prediction : out STD_LOGIC_VECTOR(7 downto 0) -- optional prediction output
           );
end uart_receiver;

architecture Behavioral of uart_receiver is
    signal rx_data    : STD_LOGIC_VECTOR(7 downto 0);  -- holds received byte
    signal rx_buffer  : STD_LOGIC_VECTOR(7 downto 0);  -- temporary storage for bytes
    signal uart_ready : STD_LOGIC := '0';              -- flag for ready signal
    signal byte_count : integer range 0 to 255 := 0;   -- simple byte counter
begin
    -- UART reception logic (simplified, requires UART receiver module)
    uart_rx : process(clk, rst)
    begin
        if rst = '1' then
            rx_data <= (others => '0');
            byte_count <= 0;
            uart_ready <= '0';
        elsif rising_edge(clk) then
            -- Wait for new data and collect byte-by-byte
            if rx = '1' then
                rx_data <= rx_buffer;
                byte_count <= byte_count + 1;
                uart_ready <= '1';
            end if;

            -- After receiving a full patch, you could process and output predictions here
            if byte_count = 1024 then  -- example: full patch received (32x32 = 1024 bytes)
                -- Process image data or make a prediction
                byte_count <= 0;
                uart_ready <= '0';  -- reset to receive next data
            end if;
        end if;
    end process;

end Behavioral;
