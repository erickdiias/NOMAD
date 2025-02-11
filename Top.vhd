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
        sensor_hall : in std_logic_vector(2 downto 0);
        D0_a        : out std_logic_vector(3 downto 0);
        D1_a        : out std_logic_vector(3 downto 0);
        D0_seg      : out std_logic_vector(6 downto 0);
        D1_seg      : out std_logic_vector(6 downto 0)
    );
end entity;

architecture main of Top is
    
    signal setpoint : std_logic_vector(13 downto 0);
    signal mensurado : std_logic_vector(13 downto 0);
    signal bcd_16bits_setpoint : std_logic_vector(15 downto 0);
    signal bcd_16bits_mensurado : std_logic_vector(15 downto 0);

begin

    setpoint_inst: entity work.Setpoint
        port map(
            clk => clk,
            rst => rst,
            button => button,
            sw => sw,
            setpoint => setpoint
        );

    mensurado_inst: entity work.Mensurado
        generic map(
            clk_freq => 100_000_000,
            pares_polos => 2
        )
        port map(
            clk => clk,
            rst => rst,
            sensor_hall => sensor_hall,
            mensurado => mensurado
        );

    bin2bcd_inst: entity work.bin2bcd
        port map(
            bin_14bits_setpoint => setpoint,
            bin_14bits_mensurado => mensurado,
            bcd_16bits_setpoint => bcd_16bits_setpoint,
            bcd_16bits_mensurado => bcd_16bits_mensurado
        );

    display_inst: entity work.Display
        port map(
            clk => clk,
            bcd_16bits_setpoint => bcd_16bits_setpoint,
            bcd_16bits_mensurado => bcd_16bits_mensurado,
            D0_a => D0_a,
            D1_a => D1_a,
            D0_seg => D0_seg,
            D1_seg => D1_seg
        );

end architecture;