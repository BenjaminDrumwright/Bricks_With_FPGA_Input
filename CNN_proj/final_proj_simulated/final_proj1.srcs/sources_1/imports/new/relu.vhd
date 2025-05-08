-- relu.vhd
-- Implements a ReLU activation layer. For unsigned pixel data, this effectively acts as a pass-through 
-- since all values are ≥ 0. FSM ensures one-cycle latency between input and output stages.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cnn_types.ALL;

entity relu is
    Port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        start  : in  std_logic;          -- Trigger processing of the input
        done   : out std_logic;          -- Indicates output is ready
        input  : in  patch_type;         -- 32x32 input patch
        output : out patch_type          -- 32x32 output patch (identical)
    );
end relu;

architecture Behavioral of relu is
    -- Simple FSM states
    type state_t is (IDLE, WORK, DONE_S);
    signal state : state_t := IDLE;

    -- Temporary storage for output
    signal temp  : patch_type := (others => (others => (others => '0')));
begin
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset internal state and outputs
            temp   <= (others => (others => (others => '0')));
            output <= (others => (others => (others => '0')));
            done   <= '0';
            state  <= IDLE;

        elsif rising_edge(clk) then
            case state is

                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        -- Load input into temp (no thresholding needed)
                        temp  <= input;
                        state <= WORK;
                    end if;

                when WORK =>
                    -- Pass-through stage
                    output <= temp;
                    done   <= '1';
                    state  <= DONE_S;

                when DONE_S =>
                    -- Wait for 'start' to fall before allowing a new pass
                    if start = '0' then
                        done  <= '0';
                        state <= IDLE;
                    end if;

            end case;
        end if;
    end process;
end Behavioral;

