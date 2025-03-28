library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PI_Controle is
    generic(
        kp : integer := 10;
        ki : integer := 1;
        kd : integer := 0
    );
    Port(
        clk      : in std_logic;
        rst      : in std_logic; 
        erro     : in integer;
        duty_cycle : out integer
    );
end entity;

architecture main of PI_Controle is
    constant PWM_MAX : integer := 255;
    
    signal erro_anterior : integer := 0;
    signal integral      : integer := 0;
    signal derivada      : integer := 0;
    
    signal output_PID : integer := 0;
    signal output_PWM : integer := 0;

begin
    process(clk, rst)
    begin
        if rst = '1' then
            erro_anterior <= 0;
            integral <= 0;
            derivada <= 0;
            output_PID <= 0;
            output_PWM <= 0;

        elsif rising_edge(clk) then
            integral <= integral + erro;
            derivada <= erro - erro_anterior;
            output_PID <= (erro * kp) + (integral * ki) + (derivada * kd);

            if output_PID < 0 then
                output_PWM <= 0;
            elsif output_PID > PWM_MAX then
                output_PWM <= PWM_MAX;
            else
                output_PWM <= output_PID;
            end if;

            erro_anterior <= erro;
        end if;
    end process;

    duty_cycle <= output_PWM;

end architecture;
