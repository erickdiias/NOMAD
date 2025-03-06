-- Descrição: 
--
-- Autor: Erick S. Dias
-- Ultima Atualização: 06/03/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Controlador_logico is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        sensor_hall : in std_logic_vector(2 downto 0);
        duty_cycle  : in integer range 0 to 255; -- Duty cycle (0 a 255)
        pwmA_sup : out std_logic;
        pwmA_inf : out std_logic;
        pwmB_sup : out std_logic;
        pwmB_inf : out std_logic;
        pwmC_sup : out std_logic;
        pwmC_inf : out std_logic
    );
end entity; 

architecture main of Controlador_logico is
    signal estado_atual_hall : std_logic_vector(2 downto 0);
    signal ultimo_estado_hall : std_logic_vector(2 downto 0) := "000";
    signal pwm_counter : integer range 0 to 255 := 0;
    signal pwm_enable  : std_logic := '0'; 

begin

    -- Gerador de PWM
    process(clk, rst)
    begin
        if rst = '1' then
            pwm_counter <= 0;
            pwm_enable  <= '0';
        elsif rising_edge(clk) then
            if pwm_counter < 255 then
                pwm_counter <= pwm_counter + 1;
            else
                pwm_counter <= 0;
            end if;

            -- PWM ativo quando o contador é menor que o duty cycle
            if pwm_counter < duty_cycle then
                pwm_enable <= '1';
            else
                pwm_enable <= '0';
            end if;
        end if;
    end process;

    -- Comutação com modulação PWM
    process(clk, rst)
    begin
        if rst = '1' then
            pwmA_sup <= '0'; pwmA_inf <= '0';
            pwmB_sup <= '0'; pwmB_inf <= '0';
            pwmC_sup <= '0'; pwmC_inf <= '0';
            ultimo_estado_hall <= "000";

        elsif rising_edge(clk) then
            estado_atual_hall <= sensor_hall;

            if estado_atual_hall /= ultimo_estado_hall then
                ultimo_estado_hall <= estado_atual_hall;

                case estado_atual_hall is
                    when "001" =>  -- Estado 1: A+ PWM, B- ligado
                        pwmA_sup <= pwm_enable; pwmA_inf <= '0';
                        pwmB_sup <= '0'; pwmB_inf <= '1';
                        pwmC_sup <= '0'; pwmC_inf <= '0';

                    when "010" =>  -- Estado 2: A+ PWM, C- ligado
                        pwmA_sup <= pwm_enable; pwmA_inf <= '0';
                        pwmB_sup <= '0'; pwmB_inf <= '0';
                        pwmC_sup <= '0'; pwmC_inf <= '1';

                    when "011" =>  -- Estado 3: B+ PWM, C- ligado
                        pwmA_sup <= '0'; pwmA_inf <= '0';
                        pwmB_sup <= pwm_enable; pwmB_inf <= '0';
                        pwmC_sup <= '0'; pwmC_inf <= '1';

                    when "100" =>  -- Estado 4: B+ PWM, A- ligado
                        pwmA_sup <= '0'; pwmA_inf <= '1';
                        pwmB_sup <= pwm_enable; pwmB_inf <= '0';
                        pwmC_sup <= '0'; pwmC_inf <= '0';

                    when "101" =>  -- Estado 5: C+ PWM, A- ligado
                        pwmA_sup <= '0'; pwmA_inf <= '1';
                        pwmB_sup <= '0'; pwmB_inf <= '0';
                        pwmC_sup <= pwm_enable; pwmC_inf <= '0';

                    when "110" =>  -- Estado 6: C+ PWM, B- ligado
                        pwmA_sup <= '0'; pwmA_inf <= '0';
                        pwmB_sup <= '0'; pwmB_inf <= '1';
                        pwmC_sup <= pwm_enable; pwmC_inf <= '0';

                    when others =>  -- Estado inválido (motor desligado)
                        pwmA_sup <= '0'; pwmA_inf <= '0';
                        pwmB_sup <= '0'; pwmB_inf <= '0';
                        pwmC_sup <= '0'; pwmC_inf <= '0';
                end case;
            end if;
        end if;
    end process;

end architecture;
