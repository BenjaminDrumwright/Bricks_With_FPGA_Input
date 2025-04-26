library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.cnn_types.all;

entity cnn_top is
    Port (
        clk, rst  : in  std_logic;
		start	  : in  std_logic;
		done      : out std_logic;
        patch_in  : in  patch_type;
        output    : out std_logic_vector(8191 downto 0)
    );
end cnn_top;

architecture Structural of cnn_top is

    signal conv1_out, relu1_out : patch_type;
    signal conv2_out, relu2_out : patch_type;
    signal conv3_out, relu3_out : patch_type;
    signal flatten_out          : std_logic_vector(8191 downto 0);
    signal FC_out               : std_logic_vector(8191 downto 0); -- assuming same size as flatten output
	signal done1, done2, done3, 
	 done4, done5, done6, done7 : std_logic;

begin

    -- Convolution Layer 1
    Conv1: entity work.conv_layer
        port map (
            clk      => clk,
			rst      => rst,
			start    => start,
            patch_in => patch_in,
            feature  => conv1_out,
			done     => done1
        );

    -- ReLU 1
    ReLU1: entity work.relu
        port map (
			clk    => clk,
			rst    => rst,
			start  => done1,
            input  => conv1_out,
            output => relu1_out,
			done   => done2
        );

    -- Convolution Layer 2
    Conv2: entity work.conv_layer
        port map (
            clk      => clk,
			rst      => rst,
			start    => done2
            patch_in => relu1_out,
            feature  => conv2_out,
			done     => done3
        );

    -- ReLU 2
    ReLU2: entity work.relu
        port map (
			clk    => clk,
			rst    => rst,
			start  => done3,
            input  => conv2_out,
            output => relu2_out,
			done   => done4
        );

    -- Convolution Layer 3
    Conv3: entity work.conv_layer
        port map (
            clk      => clk,
			rst      => rst,
			start    => done4,
            patch_in => relu2_out,
            feature  => conv3_out,
			done     => done5
        );

    -- ReLU 3
    ReLU3: entity work.relu
        port map (
			clk    => clk,
			rst    => rst,
			start  => done5,
            input  => conv3_out,
            output => relu3_out,
			done   => done6
        );

    -- Flatten Layer
    Flatten: entity work.flatten
        port map (
            input  => relu3_out,
            output => flatten_out
        );

    -- Fully Connected Layer
    FC: entity work.FC_layer
        port map (
			clk    => clk,
			rst    => rst,
			start  => done6,
            input  => flatten_out,
            output => FC_out,
			done   => done7
        );

    -- Output assignment
    output <= FC_out;

end Structural;
