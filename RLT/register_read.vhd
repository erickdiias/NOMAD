library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_read is
    port(
        clk : in std_logic;
        rst : in std_logic;
        sensor_hall : in std_logic_vector(3 downto 0);
        regout : out std_logic_vector(31 downto 0) --
    );

end entity register_read;

architecture rtl of register_read is
begin
end architecture rtl;