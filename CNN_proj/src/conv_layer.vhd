library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all; -- to use patch layer


entity conv_layer is
  Port (
    clk : in std_logic; 
    input : in patch_type;
    output : out patch_type
   );
end conv_layer;

architecture Behavioral of conv_layer is

begin


end Behavioral;

