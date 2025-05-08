library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;

entity cnn_top is
    Port (
        clk, rst : in std_logic;
        rx       : in std_logic; -- UART RX line from Pi
        tx       : out std_logic; -- UART TX line back to Pi
        done     : out std_logic;
        output   : out std_logic_vector(3 downto 0) -- 4-bit prediction
    );
end cnn_top;

architecture Structural of cnn_top is

    -- CNN Internal signals
    signal conv1_out, relu1_out : patch_type;
    signal conv2_out, relu2_out : patch_type;
    signal conv3_out, relu3_out : patch_type;
    signal flatten_out          : std_logic_vector(8191 downto 0);
    signal FC_out               : std_logic_vector(3 downto 0);

    signal done1, done2, done3, done4, done5, done6, done7 : std_logic;

    -- UART RX signals
    signal uart_data     : std_logic_vector(7 downto 0);
    signal uart_ready    : std_logic;
    signal patch_buffer  : std_logic_vector(8191 downto 0) := (others => '0');
    signal patch_in      : patch_type;
    signal byte_counter  : integer range 0 to 1024 := 0;
    signal start_cnn     : std_logic := '0';

    -- UART TX signals
    signal send_result   : std_logic := '0';
    signal uart_busy     : std_logic;
    signal output_reg    : std_logic_vector(3 downto 0);

begin

    -- UART Receiver instance
    UART_RX_inst : entity work.uart_rx
        port map (
            clk        => clk,
            rst        => rst,
            rx         => rx,
            data_out   => uart_data,
            data_ready => uart_ready
        );

    -- UART Transmitter instance
    UART_TX_inst : entity work.uart_tx
        port map (
            clk       => clk,
            rst       => rst,
            tx_start  => send_result,
            tx_data   => "0000" & output_reg, -- 8 bits total
            tx        => tx,
            tx_busy   => uart_busy
        );

    -- Patch loading logic
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                patch_buffer <= (others => '0');
                byte_counter <= 0;
                start_cnn <= '0';
            else
                if uart_ready = '1' then
                    patch_buffer((8191 - byte_counter*8) downto (8191 - byte_counter*8 - 7)) <= uart_data;
                    if byte_counter = 1023 then
                        byte_counter <= 0;
                        start_cnn <= '1'; -- Full patch received, start CNN
                    else
                        byte_counter <= byte_counter + 1;
                    end if;
                else
                    start_cnn <= '0'; -- Clear start signal unless new patch
                end if;
            end if;
        end if;
    end process;

    -- Unpack patch_buffer into patch_in (combinational)
    process(patch_buffer)
    begin
        for i in 0 to 31 loop
            for j in 0 to 31 loop
                patch_in(i,j) <= patch_buffer((i*32 + j)*8 + 7 downto (i*32 + j)*8);
            end loop;
        end loop;
    end process;

    -- CNN Structure
    Conv1: entity work.conv_layer
        port map (
            clk      => clk,
            rst      => rst,
            start    => start_cnn,
            patch_in => patch_in,
            feature  => conv1_out,
            done     => done1
        );

    ReLU1: entity work.relu
        port map (
            clk    => clk,
            rst    => rst,
            start  => done1,
            input  => conv1_out,
            output => relu1_out,
            done   => done2
        );

    Conv2: entity work.conv_layer
        port map (
            clk      => clk,
            rst      => rst,
            start    => done2,
            patch_in => relu1_out,
            feature  => conv2_out,
            done     => done3
        );

    ReLU2: entity work.relu
        port map (
            clk    => clk,
            rst    => rst,
            start  => done3,
            input  => conv2_out,
            output => relu2_out,
            done   => done4
        );

    Conv3: entity work.conv_layer
        port map (
            clk      => clk,
            rst      => rst,
            start    => done4,
            patch_in => relu2_out,
            feature  => conv3_out,
            done     => done5
        );

    ReLU3: entity work.relu
        port map (
            clk    => clk,
            rst    => rst,
            start  => done5,
            input  => conv3_out,
            output => relu3_out,
            done   => done6
        );

    Flatten: entity work.flatten
        port map (
            input  => relu3_out,
            output => flatten_out
        );

    FC: entity work.FC_layer
        port map (
            clk    => clk,
            rst    => rst,
            start  => done6,
            input  => flatten_out,
            output => FC_out,
            done   => done7
        );

    -- Handle result sending after CNN done
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                send_result <= '0';
                output_reg <= (others => '0');
            else
                if done7 = '1' then
                    output_reg <= FC_out;
                    send_result <= '1'; -- Trigger UART TX send
                elsif uart_busy = '0' then
                    send_result <= '0'; -- Clear after sending
                end if;
            end if;
        end if;
    end process;

    -- Final assignments
    output <= FC_out;
    done   <= done7;

end Structural;
