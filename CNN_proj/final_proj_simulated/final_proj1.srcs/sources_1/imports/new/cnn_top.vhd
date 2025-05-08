-- cnn_top.vhd
-- Receives image data over UART, processes through conv, relu, flatten,
-- and fully connected layers, then transmits classification result via UART.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cnn_types.ALL;
use work.cnn_weights.ALL;

entity cnn_top is
    Port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        rx   : in  std_logic; -- recieving from uart
        tx   : out std_logic -- sending to uart
    );
end cnn_top;

architecture Structural of cnn_top is
    -- pipeline data
    signal patch_in     : patch_type;                -- structured patch input
    signal conv_out     : patch_type;                -- output of convolution layer
    signal relu_out     : patch_type;                -- output of ReLU layer
    signal flat_out     : flat_type;                 -- flattened ReLU output
    signal class_out    : std_logic_vector(4 downto 0); -- predicted class index

    -- handshakes
    signal patch_ready, patch_consumed : std_logic;  -- loader <-> FSM handshake
    signal conv_start, conv_done       : std_logic;  -- FSM <-> conv
    signal relu_start, relu_done       : std_logic;  -- FSM <-> relu
    signal fc_start,   fc_done         : std_logic;  -- FSM <-> fc

    -- UART I/O
    signal rx_data   : std_logic_vector(7 downto 0);
    signal rx_valid  : std_logic;
    signal tx_start  : std_logic;
    signal tx_busy   : std_logic;
    signal tx_data   : std_logic_vector(7 downto 0);

    -- FSM
    type state_t is (
        IDLE,   -- wait for patch
        LOAD,   -- unused
        CONV,   -- start conv
        RELU,   -- start relu
        FLAT,   -- flatten (implicit)
        FC,     -- start FC layer
        SEND    -- send class result
    );
    signal state : state_t := IDLE;
begin
    -- RX
    uart_rx_inst: entity work.uart_rx
        port map(clk=>clk, rst=>rst, rx=>rx,
                 rx_data=>rx_data, rx_valid=>rx_valid);

    patch_loader_inst: entity work.patch_loader
        port map(clk=>clk, rst=>rst, rx_data=>rx_data,
                 rx_valid=>rx_valid, patch_consumed=>patch_consumed,
                 patch_ready=>patch_ready, patch_out=>patch_in);

    conv_inst: entity work.conv_layer
        port map(clk=>clk, rst=>rst, start=>conv_start,
                 done=>conv_done, input=>patch_in, output=>conv_out);

    relu_inst: entity work.relu
        port map(clk=>clk, rst=>rst, start=>relu_start,
                 done=>relu_done, input=>conv_out, output=>relu_out);

    flatten_inst: entity work.flatten
        port map(clk=>clk, input=>relu_out, output=>flat_out);

    fc_inst: entity work.fc_layer
        port map(clk=>clk, rst=>rst, input=>flat_out,
                 weights=>fc_weights, biases=>fc_biases,
                 start=>fc_start, done=>fc_done, output=>class_out);

    uart_tx_inst: entity work.uart_tx
        port map(clk=>clk, rst=>rst, tx_start=>tx_start,
                 tx_data=>tx_data, tx=>tx, tx_busy=>tx_busy);

    -- control FSM
    process(clk, rst)
    begin
        if rst = '1' then
            state            <= IDLE;
            patch_consumed   <= '0';
            conv_start       <= '0';
            relu_start       <= '0';
            fc_start         <= '0';
            tx_start         <= '0';
        elsif rising_edge(clk) then
            -- default one-cycle pulses
            conv_start     <= '0';
            relu_start     <= '0';
            fc_start       <= '0';
            patch_consumed <= '0';
            tx_start       <= '0';

            case state is
                when IDLE =>
                    if patch_ready = '1' then
                        patch_consumed <= '1';  -- acknowledge patch and begin pipeline
                        conv_start     <= '1';
                        state          <= CONV;
                    end if;

                when CONV =>
                    if conv_done = '1' then
                        relu_start <= '1';
                        state      <= RELU;
                    end if;

                when RELU =>
                    if relu_done = '1' then
                        fc_start <= '1';  -- flatten is implicit
                        state    <= FC;
                    end if;

                when FC =>
                    if fc_done = '1' then
                        tx_data  <= (2 downto 0 => '0') & class_out; -- zero-pad to byte
                        tx_start <= '1';
                        state    <= SEND;
                    end if;

                when SEND =>
                    if tx_busy = '0' then
                        state <= IDLE;  -- ready for next patch
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end Structural;
