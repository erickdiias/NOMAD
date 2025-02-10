-- top.vhd
-- 
-- 
-- 

library ieee;
use ieee.std_logic_1164.all;

entity Top is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        button      : in std_logic;
        sw          : in std_logic_vector(3 downto 0);
        D0_a        : out std_logic_vector(3 downto 0);
        D0_seg      : out std_logic_vector(6 downto 0)
    );
end entity;

architecture main of Top is
    
    signal setpoint : std_logic_vector(13 downto 0);
    signal bcd_16bits : std_logic_vector(15 downto 0);

begin

    setpoint_inst: entity work.Setpoint
        port map(
            clk => clk,
            rst => rst,
            button => button,
            sw => sw,
            setpoint => setpoint
        );

    bin2bcd_inst: entity work.bin2bcd
        port map(
            bin_14bits => setpoint,
            bcd_16bits => bcd_16bits
        );

    display_inst: entity work.Display
        port map(
            clk => clk,
            bcd_16bits => bcd_16bits,
            D0_a => D0_a,
            D0_seg => D0_seg
        );

end architecture;