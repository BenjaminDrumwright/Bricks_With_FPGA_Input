-- conv_layer.vhd
-- Implements a fixed 3x3 convolution kernel (all ones) on a 32x32 image patch. Outputs a blurred 
-- image using box filter logic (sum + divide by 9), with a finite state machine (FSM) managing 
-- accumulation, scaling, and output. Border pixels are zeroed out to avoid boundary issues.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.ALL;

entity conv_layer is
    Port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;         -- One-cycle pulse to begin computation
        done   : out std_logic;         -- Goes high when output is valid
        input  : in  patch_type;        -- 32x32 8-bit image patch
        output : out patch_type         -- 32x32 8-bit processed patch
    );
end conv_layer;

architecture Behavioral of conv_layer is
    -- 12-bit accumulation matrix to store convolution results (8-bit input * 9 max = 12 bits max sum)
    type sum_mat_t is array (0 to 31, 0 to 31) of unsigned(11 downto 0);
    signal sum_mat    : sum_mat_t := (others => (others => (others => '0')));

    -- Temporary patch to store scaled 8-bit output before final write
    signal temp_patch : patch_type := (others => (others => (others => '0')));

    -- FSM to track pipeline stages
    type state_t is (IDLE, ACCUM, SCALE, DONE_S);
    signal state : state_t := IDLE;

begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all internal state and outputs
            sum_mat    <= (others => (others => (others => '0')));
            temp_patch <= (others => (others => (others => '0')));
            output     <= (others => (others => (others => '0')));
            done       <= '0';
            state      <= IDLE;

        elsif rising_edge(clk) then
            case state is

                when IDLE =>
                    done <= '0';  -- Clear done flag
                    if start = '1' then
                        -- Step 1: Convolution accumulation (box filter)
                        -- For each pixel (except 1-pixel border), sum its 3x3 neighborhood
                        for i in 1 to 30 loop
                            for j in 1 to 30 loop
                                sum_mat(i,j) <=
                                    resize(unsigned(input(i-1,j-1)),12) +
                                    resize(unsigned(input(i-1,j  )),12) +
                                    resize(unsigned(input(i-1,j+1)),12) +
                                    resize(unsigned(input(i  ,j-1)),12) +
                                    resize(unsigned(input(i  ,j  )),12) +
                                    resize(unsigned(input(i  ,j+1)),12) +
                                    resize(unsigned(input(i+1,j-1)),12) +
                                    resize(unsigned(input(i+1,j  )),12) +
                                    resize(unsigned(input(i+1,j+1)),12);
                            end loop;
                        end loop;
                        state <= ACCUM;
                    end if;

                when ACCUM =>
                    -- Step 2: Scale result down by dividing by 9 to compute average
                    -- Only applies to interior (1 to 30) pixels
                    for i in 1 to 30 loop
                        for j in 1 to 30 loop
                            temp_patch(i,j) <=
                                std_logic_vector(resize(sum_mat(i,j) / 9, 8));  -- Truncate to 8 bits
                        end loop;
                    end loop;

                    -- Zero out borders (since they were skipped during accumulation)
                    for k in 0 to 31 loop
                        temp_patch(0, k)  <= (others => '0');
                        temp_patch(31,k)  <= (others => '0');
                        temp_patch(k, 0)  <= (others => '0');
                        temp_patch(k,31)  <= (others => '0');
                    end loop;

                    state <= SCALE;

                when SCALE =>
                    -- Step 3: Write final processed patch to output
                    output <= temp_patch;
                    done   <= '1';    -- Signal that output is now valid
                    state  <= DONE_S;

                when DONE_S =>
                    -- Step 4: Wait until 'start' goes low to reset FSM
                    if start = '0' then
                        done  <= '0';
                        state <= IDLE;
                    end if;

            end case;
        end if;
    end process;
end Behavioral;

