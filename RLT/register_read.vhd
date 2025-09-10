library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_read is
    port(
        clk : in std_logic;
        rst : in std_logic;
        sensor_hall : in std_logic_vector(3 downto 0)
    );