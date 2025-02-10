-- File: Setpoint.vhd
-- Descricao:   O arquivo eh responsavel por gerar o valor de setpoint com base nos valores dos de 4 switches e a confirmacao de 1 botao pressionado.
--              Esse valor variando de 0 a 15, eh multiplicado por 665 e atribuido a saida setpoint de 14 bits.
-- Autor: Erick S. Dias
-- Ultima atualizacao: 09/02/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Setpoint is
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        button   : in std_logic;
        sw       : in std_logic_vector(3 downto 0); 
        setpoint : out std_logic_vector(13 downto 0)
    );
end entity;

architecture main of Setpoint is
    signal valor : integer := 0;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            valor <= 0; 
        elsif rising_edge(clk) then
            if button = '1' then
                if to_integer(unsigned(sw)) <= 15 then
                    valor <= to_integer(unsigned(sw)) * 665;
                else
                    valor <= 9975; -- RPM_MAX
                end if;
            end if;
        end if;
    end process;
                    
    setpoint <= std_logic_vector(to_unsigned(valor, 14)); 

end architecture;
