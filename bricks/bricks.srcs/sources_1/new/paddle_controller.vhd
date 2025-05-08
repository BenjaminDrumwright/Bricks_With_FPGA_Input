-- paddle_controller.vhd
-- Takes buttons as input and sends out to python via uart (uart_tx.vhd)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity paddle_controller is
    Port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        btnL    : in  std_logic; -- Left button
        btnR    : in  std_logic; -- Right button
        btnC    : in  std_logic; -- Center button
        btnT    : in  std_logic; -- Top button
        btnB    : in  std_logic; -- Bottom button
        uart_tx : out std_logic  -- bit being sent over uart
    );
end paddle_controller;

architecture Behavioral of paddle_controller is
    signal tx_data   : std_logic_vector(7 downto 0) := (others => '0'); --holds hex value to be sent across uart
    signal tx_start  : std_logic := '0'; -- tells uart_tx to start processing tx_data
    signal tx_busy   : std_logic;  -- tells if uart is busy sending data
    signal btnL_prev, btnR_prev, btnC_prev, btnT_prev, btnB_prev : std_logic := '0';
begin

    process(clk)
    begin
        -- Eveerything is synchronized to the clock edge
        if rising_edge(clk) then
            -- Clear all data on reset
            if rst = '1' then
                tx_start <= '0';
                tx_data  <= (others => '0');
                btnL_prev <= '0';
                btnR_prev <= '0';
                btnC_prev <= '0';
                btnT_prev <= '0';
                btnB_prev <= '0';
            -- If a button is high and wasn't before, set tx_data to hex value of corresponidng letter and start processing
            else
                if btnL = '1' and btnL_prev = '0' then
                    tx_data <= x"4C";  -- 'L' (Left for the paddle)
                    tx_start <= '1';
                elsif btnR = '1' and btnR_prev = '0' then
                    tx_data <= x"52";  -- 'R' (Right for the paddle)
                    tx_start <= '1';
                elsif btnC = '1' and btnC_prev = '0' then
                    tx_data <= x"53";  -- 'S' (Start or Select)
                    tx_start <= '1';
                elsif btnT = '1' and btnT_prev = '0' then
                    tx_data <= x"55";  -- 'U' (Up in alphabet)
                    tx_start <= '1';
                elsif btnB = '1' and btnB_prev = '0' then
                    tx_data <= x"44";  -- 'D' (Down in alphabet)
                    tx_start <= '1';
                else
                    tx_start <= '0';
                end if;
                -- Registers for button signals to ensure button doesn't work when held down
                btnL_prev <= btnL;
                btnR_prev <= btnR;
                btnC_prev <= btnC;
                btnT_prev <= btnT;
                btnB_prev <= btnB;
            end if;
        end if;
    end process;
    -- Instantiation of uart_tx module to send tx_data across uart
    uart_inst : entity work.uart_tx
        port map (
            clk      => clk,
            rst      => rst,
            tx_start => tx_start, 
            tx_data  => tx_data, 
            tx       => uart_tx, 
            tx_busy  => tx_busy 
        );
end Behavioral;





