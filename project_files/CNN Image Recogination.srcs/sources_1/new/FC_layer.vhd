library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;

entity FC_layer is
     Port ( 
        input : in std_logic_vector(8191 downto 0);
        output : out std_logic_vector(3 downto 0) -- for 4 typees of objects
     );
     
end FC_layer;

architecture Behavioral of FC_layer is

begin


end Behavioral;
