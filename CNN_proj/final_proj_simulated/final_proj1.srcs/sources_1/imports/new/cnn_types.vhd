-- cnn_types.vhd
-- Defines common data types used throughout the CNN pipeline, including pixel format, 2D image patches, 
-- flattened vectors, and fully connected layer weights and biases.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package cnn_types is
    subtype pixel is std_logic_vector(7 downto 0);
    type patch_type is array (0 to 31, 0 to 31) of pixel;
    type flat_type is array (0 to 1023) of pixel;
    type fc_weight_array is array(0 to 19, 0 to 1023) of std_logic;
    type fc_bias_array is array(0 to 19) of std_logic;

end package;
