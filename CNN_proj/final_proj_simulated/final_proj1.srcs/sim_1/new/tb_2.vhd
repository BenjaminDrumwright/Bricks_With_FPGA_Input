library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_cnn_top is
end tb_cnn_top;

architecture sim of tb_cnn_top is
    -- Clock and UART timing parameters
    constant CLK_PERIOD  : time := 10 ns;            -- 100 MHz
    constant BAUD_RATE   : integer := 115200;
    constant BIT_PERIOD  : time := 1 sec / BAUD_RATE; -- ?8.68 µs

    -- DUT I/O
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal rx  : std_logic := '1';
    signal tx  : std_logic;

    -- Procedure for UART byte send
    procedure uart_send_byte(
        signal rx_line : out std_logic;
        data            : in std_logic_vector(7 downto 0)
    ) is
    begin
        -- Start bit
        rx_line <= '0';
        wait for BIT_PERIOD;
        -- Data bits (LSB first)
        for bit_pos in 0 to 7 loop
            rx_line <= data(bit_pos);
            wait for BIT_PERIOD;
        end loop;
        -- Stop bit
        rx_line <= '1';
        wait for BIT_PERIOD;
    end procedure uart_send_byte;

begin
    ----------------------------------------------------------------
    -- Clock generator
    ----------------------------------------------------------------
    clk_proc : process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;

    ----------------------------------------------------------------
    -- Instantiate CNN top-level
    ----------------------------------------------------------------
    uut: entity work.cnn_top
        port map(
            clk => clk,
            rst => rst,
            rx  => rx,
            tx  => tx
        );

    ----------------------------------------------------------------
    -- Reset sequence
    ----------------------------------------------------------------
    rst_proc: process
    begin
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait;
    end process;

    ----------------------------------------------------------------
    -- Stimulus: send a 32×32 patch of zeros then monitor TX
    ----------------------------------------------------------------
    stim_proc: process
        variable pixel : std_logic_vector(7 downto 0) := (others => '0');
    begin
        -- Wait until reset release
        wait until rst = '0';
        wait for CLK_PERIOD * 10;

        -- Send 1024 bytes (32×32 pixels)
        for idx in 0 to 1023 loop
            uart_send_byte(rx, pixel);
            -- Small gap
            wait for BIT_PERIOD;
        end loop;

        -- Allow time for processing and TX output
        wait for 5 ms;

        -- Indicate end of simulation
        assert false report "Simulation complete: check TX waveform for class output" severity note;
        wait;
    end process;

end architecture sim;
