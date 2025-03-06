--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Commutation is
    port(
        clk : in std_logic;
        rst : in std_logic;
        sensor_hall : in std_logic_vector(2 downto 0);
        pwmA_sup, pwmA_inf : out std_logic;
        pwmB_sup, pwmB_inf : out std_logic;
        pwmC_sup, pwmC_inf : out std_logic;
    );
end entity; 

architecture main of Commutation is
    signal estado_hall : std_logic_vector(2 downto 0);
    signal ultimo_estado_hall : std_logic_vector(2 downto 0) := "000";

    signal contagem : integer := 0;
    signal velocidade_ref   : integer := 10000; -- Referência de velocidade
    signal pwm_duty    : integer := 5000;  -- PWM inicial
begin
    process(clk)
    begin
        if rising_edge(clk) then
            estado_atual_hall <= sensor_hall;
            if estado_atual_hall /= ultimo_estado_hall then
                ultimo_estado_hall <= estado_atual_hall;
                case estado_atual_hall is
                    when "001" =>
                        pwmA_sup <= '1';
                    when "010" =>
                        pwmA_sup <= '1';
                    when "011" =>
                        pwmB_sup <= '1';
                    when "100" =>
                        pwmB_sup <= '1';
                    when "101" =>
                        pwmC_sup <= '1';
                    when "110" =>
                        pwmC_sup <= '1';
                    when others =>
                        pwmA_sup <= '0'; pwmB_sup <= '0'; pwmC_sup <= '0';
                        pwmA_inf <= '0'; pwmB_inf <= '0'; pwmC_inf <= '0';
                end case;
            end if;
        end if;
    end process;
end architecture ;


teste