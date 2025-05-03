library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.ALL;

entity fc_layer is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        input   : in  flat_type;
        weights : in  fc_weight_array;
        biases  : in  fc_bias_array;
        start   : in  std_logic;
        done    : out std_logic;
        output  : out std_logic_vector(4 downto 0)
    );
end fc_layer;

architecture Behavioral of fc_layer is
    type score_array is array(0 to 19) of unsigned(31 downto 0);
    signal scores     : score_array := (others => (others => '0'));
    signal idx_class  : integer range 0 to 19   := 0;
    signal idx_feat   : integer range 0 to 1023 := 0;
    type state_t is (IDLE, ACCUM, BIAS_ARG, DONE_S);
    signal state      : state_t := IDLE;
begin
    process(clk, rst)
        variable v_max_score : unsigned(31 downto 0);
        variable v_max_idx   : integer range 0 to 19;
        variable i           : integer;
    begin
        if rst = '1' then
            scores     <= (others => (others => '0'));
            idx_class  <= 0;
            idx_feat   <= 0;
            done       <= '0';
            output     <= (others => '0');
            state      <= IDLE;

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    done <= '0';
                    if start = '1' then
                        scores    <= (others => (others => '0'));
                        idx_class <= 0;
                        idx_feat  <= 0;
                        state     <= ACCUM;
                    end if;

                when ACCUM =>
                    if weights(idx_class, idx_feat) = '1' then
                        scores(idx_class) <= scores(idx_class) + resize(unsigned(input(idx_feat)), 32);
                    end if;
                    if idx_feat = 1023 then
                        idx_feat  <= 0;
                        if idx_class = 19 then
                            state <= BIAS_ARG;
                        else
                            idx_class <= idx_class + 1;
                        end if;
                    else
                        idx_feat <= idx_feat + 1;
                    end if;

                when BIAS_ARG =>
                    -- add biases
                    for i in 0 to 19 loop
                        if biases(i) = '1' then
                            scores(i) <= scores(i) + 1;
                        end if;
                    end loop;
                    -- compute argmax using variables
                    v_max_score := scores(0);
                    v_max_idx   := 0;
                    for i in 1 to 19 loop
                        if scores(i) > v_max_score then
                            v_max_score := scores(i);
                            v_max_idx   := i;
                        end if;
                    end loop;
                    output <= std_logic_vector(to_unsigned(v_max_idx, 5));
                    done   <= '1';
                    state  <= DONE_S;

                when DONE_S =>
                    if start = '0' then
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;
