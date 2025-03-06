-- Controle trapezoidal de um motor brushless DC com indicação de velocidade atual e pedida 
-- 
-- 
-- 

library ieee;
use ieee.std_logic_1164.all;

entity FPGA_top is
    port(
        clk, rst, button    : in  std_logic;
        sw                  : in  std_logic_vector(3 downto 0);
        sensor_hall         : in  std_logic_vector(2 downto 0);

        led_s               : out std_logic_vector(3 downto 0);
        led_m               : out std_logic_vector(2 downto 0);

        D0_a, D1_a          : out std_logic_vector(3 downto 0);
        D0_seg, D1_seg      : out std_logic_vector(6 downto 0);

        pwmA_sup, pwmA_inf  : out std_logic;
        pwmB_sup, pwmB_inf : out std_logic;
        pwmC_sup, pwmC_inf : out std_logic;

    );
end entity;

architecture main of FPGA_top is

    signal led_setpoint : std_logic_vector(3 downto 0) := (others => '0');
    signal led_mensurado : std_logic_vector(2 downto 0) := (others => '0');
    
    signal setpoint : std_logic_vector(13 downto 0);
    signal mensurado : std_logic_vector(13 downto 0);
    signal bcd_16bits_setpoint : std_logic_vector(15 downto 0);
    signal bcd_16bits_mensurado : std_logic_vector(15 downto 0);

    signal erro : integer := 0;

    signal duty_cycle_int  : integer range 0 to 255; -- Duty cycle (0 a 255)
begin
    -- SETPOINT
    setpoint_inst: entity work.Setpoint
        port map(
            clk => clk,
            rst => rst,
            button => button,
            sw => sw,
            setpoint => setpoint
        );

    led_setpoint <= sw;
    led_s <= led_setpoint;

    -- MENSURADO
    mensurado_inst: entity work.Mensurado
        generic map(
            clk_freq => 100_000_000,
            pares_polos => 7
        )
        port map(
            clk => clk,
            rst => rst,
            sensor_hall => sensor_hall,
            mensurado => mensurado
        );

    led_mensurado <= sensor_hall;
    led_m <= led_mensurado;

    -- ERRO
    erro <= to_integer(unsigned(setpoint) - unsigned(mensurado));

    -- PI Controle
    pi_controle_inst: entity work.PI_Controle
        generic map(
            Kp => 10,
            Ki => 1,
            Kd => 0
        )
        port map(
            clk => clk,
            rst => rst,
            erro => erro,
            duty_cycle => duty_cycle_int
        );

    -- Controlador logico
    controlador_logico_inst: entity work.Controlador_logico
        port map(
            clk => clk,
            rst => rst,
            sensor_hall => sensor_hall,
            duty_cycle => duty_cycle_int,
            pwmA_sup => pwmA_sup,
            pwmA_inf => pwmA_inf,
            pwmB_sup => pwmB_sup,
            pwmB_inf => pwmB_inf,
            pwmC_sup => pwmC_sup,
            pwmC_inf => pwmC_inf
        );

    -- bin2bcd
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