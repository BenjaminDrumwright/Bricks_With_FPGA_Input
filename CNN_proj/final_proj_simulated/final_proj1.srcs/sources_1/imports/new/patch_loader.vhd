-- patch_loader.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cnn_types.ALL;

entity patch_loader is
    Port(
        clk            : in  std_logic;
        rst            : in  std_logic;
        rx_data        : in  std_logic_vector(7 downto 0);
        rx_valid       : in  std_logic;
        patch_consumed : in  std_logic;
        patch_ready    : out std_logic;
        patch_out      : out patch_type
    );
end patch_loader;

architecture Behavioral of patch_loader is
    type flat_buf_t is array (0 to 1023) of std_logic_vector(7 downto 0);
    signal flat_buffer : flat_buf_t;
    signal counter     : integer range 0 to 1023 := 0;
    signal ready_reg   : std_logic := '0';
    signal patch_reg   : patch_type := (others => (others => (others => '0')));
begin
    process(clk, rst)
    begin
        if rst = '1' then
            counter   <= 0;
            ready_reg <= '0';

        elsif rising_edge(clk) then
            if ready_reg = '1' then
                if patch_consumed = '1' then
                    ready_reg <= '0';
                    counter   <= 0;
                end if;

            elsif rx_valid = '1' then
                flat_buffer(counter) <= rx_data;
                if counter = 1023 then
                    -- unpack
                    for i in 0 to 31 loop
                        for j in 0 to 31 loop
                            patch_reg(i,j) <= flat_buffer(i*32 + j);
                        end loop;
                    end loop;
                    ready_reg <= '1';
                end if;
                counter <= (counter + 1) mod 1024;
            end if;
        end if;
    end process;

    patch_out   <= patch_reg;
    patch_ready <= ready_reg;
end Behavioral;
