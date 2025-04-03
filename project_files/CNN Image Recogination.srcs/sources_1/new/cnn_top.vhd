
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_STD.ALL;

entity cnn_top is
    Port(
        clk     : in std_logic;
        pixel_in   : in std_logic_vector(7 downto 0);
        output  : out std_logic_vector(7 downto 0)
    );
end cnn_top;

architecture Structual of cnn_top is
    signal conv1_out, relu1_out : std_logic_vector(7 downto 0);
    signal conv2_out, relu2_out : std_logic_vector(7 downto 0);
    signal conv3_out, relu3_out : std_logic_vector(7 downto 0);
    signal flatten_out          : std_logic_vector(7 downto 0); -- adjust width as needed
begin

-- hidden layer 1
Conv1: entity work.conv_layer
    port map (
        clk => clk,
        input => pixel_in,
        output => conv1_out
    ); 
    
-- relu activation
ReLU1 : entity work.relu
    port map ( 
        input => conv1_out,
        output => relu1_out
    );
    
-- hidden layer 2
Conv2: entity work.conv_layer
    port map (
        clk => clk,
        input => relu1_out,
        output => conv2_out
    ); 
-- relu activation
ReLU2 : entity work.relu
    port map ( 
        input => conv2_out,
        output => relu2_out
    );
    
-- hidden layer 3
Conv3: entity work.conv_layer
    port map (
        clk => clk,
        input => relu2_out,
        output => conv3_out
    ); 
-- relu activation  
ReLU3 : entity work.relu
    port map ( 
        input => conv3_out,
        output => relu3_out
    );
    
-- flatten
Flatten : entity work.flatten
    port map ( 
        input => relu3_out,
        output => flatten_out
        
-- output
output <= flatten_out;

end Structual;
