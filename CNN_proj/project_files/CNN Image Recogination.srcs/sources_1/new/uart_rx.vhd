library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Port (
        clk        : in  std_logic; -- FPGA clock (e.g., 100MHz)
        rst        : in  std_logic; -- Reset
        rx         : in  std_logic; -- UART serial input
        data_out   : out std_logic_vector(7 downto 0); -- received byte
        data_ready : out std_logic -- high for 1 clock when a byte is ready
    );
end uart_rx;

architecture Behavioral of uart_rx is

    constant BAUD_RATE     : integer := 115200; -- your UART baud rate
    constant CLOCK_FREQ    : integer := 100_000_000; -- your FPGA clock (PYNQ-Z2 = 100MHz)
    constant BAUD_TICKS    : integer := CLOCK_FREQ / BAUD_RATE;

    type state_type is (IDLE, START, DATA, STOP);
    signal state       : state_type := IDLE;
    signal baud_counter : integer := 0;
    signal bit_counter : integer range 0 to 7 := 0;
    signal shift_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_reg      : std_logic := '1'; -- synced rx
    signal data_ready_reg : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= IDLE;
                baud_counter <= 0;
                bit_counter <= 0;
                shift_reg <= (others => '0');
                rx_reg <= '1';
                data_ready_reg <= '0';
            else
                -- sync input to clk
                rx_reg <= rx;
                data_ready_reg <= '0';

                case state is

                    when IDLE =>
                        if rx_reg = '0' then -- Start bit detected
                            state <= START;
                            baud_counter <= 0;
                        end if;

                    when START =>
                        if baud_counter = BAUD_TICKS/2 then -- sample in middle of start bit
                            if rx_reg = '0' then
                                state <= DATA;
                                bit_counter <= 0;
                                baud_counter <= 0;
                            else
                                state <= IDLE; -- false start
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when DATA =>
                        if baud_counter = BAUD_TICKS then
                            baud_counter <= 0;
                            shift_reg(bit_counter) <= rx_reg;
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
                            baud_counter <= 0;
                            if rx_reg = '1' then -- stop bit should be 1
                                data_ready_reg <= '1';
                                state <= IDLE;
                            else
                                state <= IDLE; -- framing error, ignore
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;

    data_out <= shift_reg;
    data_ready <= data_ready_reg;

end Behavioral;
