library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FC_layer is
    Port ( 
        clk    : in std_logic;
        rst    : in std_logic;
        start  : in std_logic;
        input  : in std_logic_vector(8191 downto 0); -- Flattened 32x32x8
        output : out std_logic_vector(3 downto 0);   -- 4 classes
        done   : out std_logic
    );
end FC_layer;

architecture Behavioral of FC_layer is

    type weight_array is array(0 to 3, 0 to 8191) of std_logic; -- 4 outputs, 8192 inputs
    -- Example random weights; you would replace these with learned values
    constant weights : weight_array := (
        (others => '0'), -- Weights for class 0
        (others => '1'), -- Weights for class 1
        (others => '0'), -- Weights for class 2
        (others => '1')  -- Weights for class 3
    );

    signal scores  : signed(7 downto 0) := (others => '0'); -- Single accumulator
    signal max_idx : integer range 0 to 3 := 0; -- Output class
    signal max_val : signed(15 downto 0) := (others => '0');

    signal current_class : integer range 0 to 3 := 0;
    signal current_idx   : integer range 0 to 8191 := 0;
    signal working       : std_logic := '0';
    signal done_reg      : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                scores       <= (others => '0');
                max_val      <= (others => '0');
                max_idx      <= 0;
                current_class <= 0;
                current_idx  <= 0;
                working      <= '0';
                done_reg     <= '0';

            elsif start = '1' then
                working <= '1';
                done_reg <= '0';

            elsif working = '1' then
                -- Accumulate dot product
                if weights(current_class, current_idx) = '1' then
                    scores <= scores + (others => input(current_idx));
                end if;

                -- Step through input vector
                if current_idx < 8191 then
                    current_idx <= current_idx + 1;
                else
                    -- Finished accumulating one class
                    if current_class = 0 or scores > max_val then
                        max_val <= scores;
                        max_idx <= current_class;
                    end if;
                    
                    -- Move to next class
                    if current_class < 3 then
                        current_class <= current_class + 1;
                        current_idx <= 0;
                        scores <= (others => '0');
                    else
                        -- Finished all classes
                        working <= '0';
                        done_reg <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    output <= std_logic_vector(to_unsigned(max_idx, 4)); -- Output the predicted class
    done   <= done_reg;

end Behavioral;
