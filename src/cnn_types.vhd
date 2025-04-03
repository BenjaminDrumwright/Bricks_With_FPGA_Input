library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cnn_types is
    type patch_type is array (0 to 31, 0 to 31) of std_logic_vector(7 downto 0); -- type used for patches of pixels 32x32
end cnn_types;

package body cnn_types is
end cnn_types;

