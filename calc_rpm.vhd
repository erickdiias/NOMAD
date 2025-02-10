--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_rpm is
    port(
        clk : in std_logic;
        rst : in std_logic;
        hall0, hall1, hall2 : in std_logic;
        mensurado : out std_logic_vector(13 downto 0)
    );
end entity;

architecture main of calc_rpm is
    type estado_type is array (0 to 5) of std_logic_vector(2 downto 0);
    constant estado : estado_type := (
        "100",
        "110",
        "010",
        "011",
        "001",
        "101"
    );

    signal contador : integer := 0;

begin
    

end architecture;