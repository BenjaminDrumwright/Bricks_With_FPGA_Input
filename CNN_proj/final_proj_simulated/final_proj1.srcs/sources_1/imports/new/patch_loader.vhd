-- patch_loader.vhd
-- Receives a stream of 1024 bytes over UART (1 per clock with rx_valid), stores them into a 1D buffer, 
-- and unpacks the buffer into a 32x32 patch. Asserts patch_ready once full patch is assembled. Waits 
-- for patch_consumed to restart loading process.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cnn_types.ALL;

entity patch_loader is
    Port(
        clk            : in  std_logic;
        rst            : in  std_logic;
        rx_data        : in  std_logic_vector(7 downto 0);  -- Incoming UART byte
        rx_valid       : in  std_logic;                     -- Data valid signal
        patch_consumed : in  std_logic;                     -- Pulse from FSM to reset loader
        patch_ready    : out std_logic;                     -- Asserted when full patch is ready
        patch_out      : out patch_type                     -- Final unpacked 32x32 image patch
    );
end patch_loader;

architecture Behavioral of patch_loader is
    -- Temporary 1D buffer to hold 1024 incoming bytes
    type flat_buf_t is array (0 to 1023) of std_logic_vector(7 downto 0);
    signal flat_buffer : flat_buf_t;

    -- Counts how many bytes have been loaded
    signal counter     : integer range 0 to 1023 := 0;

    -- Internal register tracking readiness status
    signal ready_reg   : std_logic := '0';

    -- Register to hold the unpacked 32x32 patch
    signal patch_reg   : patch_type := (others => (others => (others => '0')));
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset state: clear counter and ready flag
            counter   <= 0;
            ready_reg <= '0';

        elsif rising_edge(clk) then
            if ready_reg = '1' then
                -- Patch is complete; wait for FSM to consume it
                if patch_consumed = '1' then
                    ready_reg <= '0';  -- Clear flag to start new load
                    counter   <= 0;
                end if;

            elsif rx_valid = '1' then
                -- Load next byte into buffer
                flat_buffer(counter) <= rx_data;

                if counter = 1023 then
                    -- All bytes received: convert flat buffer into 32x32 patch
                    for i in 0 to 31 loop
                        for j in 0 to 31 loop
                            patch_reg(i,j) <= flat_buffer(i*32 + j);
                        end loop;
                    end loop;
                    ready_reg <= '1';  -- Signal patch is ready
                end if;

                -- Increment or wrap counter to remain within 0–1023
                counter <= (counter + 1) mod 1024;
            end if;
        end if;
    end process;

    -- Output assignments
    patch_out   <= patch_reg;
    patch_ready <= ready_reg;
end Behavioral;

