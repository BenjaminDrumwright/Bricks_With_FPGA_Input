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
        rx   : in  std_logic; -- receiving from UART
        tx   : out std_logic  -- sending to UART
    );
end cnn_top;

architecture Structural of cnn_top is
    -- pipeline data
    signal patch_in     : patch_type;                   -- raw input patch from UART
    signal conv_out     : patch_type;                   -- output from convolution layer
    signal relu_out     : patch_type;                   -- output from ReLU layer
    signal flat_out     : flat_type;                    -- flattened output from ReLU
    signal class_out    : std_logic_vector(4 downto 0); -- final predicted class

    -- handshakes
    signal patch_ready, patch_consumed : std_logic;     -- patch_loader <-> FSM interface
    signal conv_start, conv_done       : std_logic;     -- FSM <-> conv_layer
    signal relu_start, relu_done       : std_logic;     -- FSM <-> relu
    signal fc_start,   fc_done         : std_logic;     -- FSM <-> fc_layer

    -- UART I/O
    signal rx_data   : std_logic_vector(7 downto 0);    -- byte received
    signal rx_valid  : std_logic;                       -- high when rx_data is valid
    signal tx_start  : std_logic;                       -- pulse to start UART transmission
    signal tx_busy   : std_logic;                       -- high when tx is transmitting
    signal tx_data   : std_logic_vector(7 downto 0);    -- byte to transmit

    -- FSM state definition
    type state_t is (
        IDLE,   -- wait for complete patch from UART
        LOAD,   -- (unused placeholder)
        CONV,   -- start convolution
        RELU,   -- start ReLU
        FLAT,   -- flatten layer (runs implicitly)
        FC,     -- start fully connected layer
        SEND    -- send class result via UART
    );
    signal state : state_t := IDLE;
begin
    -- UART receiver: receives one byte per cycle into rx_data
    uart_rx_inst: entity work.uart_rx
        port map(clk=>clk, rst=>rst, rx=>rx,
                 rx_data=>rx_data, rx_valid=>rx_valid);

    -- Patch loader: collects 1024 bytes and assembles 32x32 patch
    patch_loader_inst: entity work.patch_loader
        port map(clk=>clk, rst=>rst, rx_data=>rx_data,
                 rx_valid=>rx_valid, patch_consumed=>patch_consumed,
                 patch_ready=>patch_ready, patch_out=>patch_in);

    -- Convolution layer: applies 3x3 box filter
    conv_inst: entity work.conv_layer
        port map(clk=>clk, rst=>rst, start=>conv_start,
                 done=>conv_done, input=>patch_in, output=>conv_out);

    -- ReLU activation: passes values as-is (unsigned data)
    relu_inst: entity work.relu
        port map(clk=>clk, rst=>rst, start=>relu_start,
                 done=>relu_done, input=>conv_out, output=>relu_out);

    -- Flatten: 2D -> 1D (no control logic needed)
    flatten_inst: entity work.flatten
        port map(clk=>clk, input=>relu_out, output=>flat_out);

    -- Fully connected layer: computes scores and outputs class index
    fc_inst: entity work.fc_layer
        port map(clk=>clk, rst=>rst, input=>flat_out,
                 weights=>fc_weights, biases=>fc_biases,
                 start=>fc_start, done=>fc_done, output=>class_out);

    -- UART transmitter: sends 8-bit zero-padded class index
    uart_tx_inst: entity work.uart_tx
        port map(clk=>clk, rst=>rst, tx_start=>tx_start,
                 tx_data=>tx_data, tx=>tx, tx_busy=>tx_busy);

    -- Control FSM: manages dataflow through CNN pipeline
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset FSM and control signals
            state            <= IDLE;
            patch_consumed   <= '0';
            conv_start       <= '0';
            relu_start       <= '0';
            fc_start         <= '0';
            tx_start         <= '0';
        elsif rising_edge(clk) then
            -- Default all pulse-based control signals to 0 each cycle
            conv_start     <= '0';
            relu_start     <= '0';
            fc_start       <= '0';
            patch_consumed <= '0';
            tx_start       <= '0';

            case state is
                when IDLE =>
                    if patch_ready = '1' then
                        patch_consumed <= '1';  -- Notify loader to reset
                        conv_start     <= '1';  -- Start convolution
                        state          <= CONV;
                    end if;

                when CONV =>
                    if conv_done = '1' then
                        relu_start <= '1';      -- Start ReLU after conv
                        state      <= RELU;
                    end if;

                when RELU =>
                    if relu_done = '1' then
                        fc_start <= '1';        -- Start FC layer (flatten already running)
                        state    <= FC;
                    end if;

                when FC =>
                    if fc_done = '1' then
                        -- Pack 5-bit class index into lower bits of UART byte
                        tx_data  <= (2 downto 0 => '0') & class_out;
                        tx_start <= '1';
                        state    <= SEND;
                    end if;

                when SEND =>
                    if tx_busy = '0' then
                        -- Transmission complete; return to IDLE
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end Structural;

