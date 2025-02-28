-- Descricao: Leitura do Ângulo usando o Sensor AS5600
--
-- Autor: Erick S. Dias
-- Ultima atualizacao: 26/02/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AS5600 is
    generic(
        clk_as5600      : integer := 32; -- reduzir a taxa de transmissão para (100MHz/32MHz = 3,125MHz) sendo o Modo de alta velocidade: 3,4 MHz
        slave_addr      : std_logic_vector(6 downto 0) := "0110110"; -- "0x36" Endereço do dispositivo I2C (no caso, o AS5600)
        register_addr   : std_logic_vector(7 downto 0) := "00001100" -- "0x0C" Endereço do registrador para ler os dados de ângulo
    );
    port(
        clk             : in std_logic; -- Clock de entrada da FPGA
        rst             : in std_logic; -- Reset (ativo baixo)
        scl             : out std_logic; -- Linha de clock I2C
        sda             : inout std_logic; -- Linha de dados I2C (bidirecional)
        start           : in  std_logic; -- Inicia a comunicação quando em nível alto
        ready           : out std_logic; -- Indica que o módulo está pronto para iniciar
        done            : out std_logic; -- Indica que a leitura foi concluída
        angle           : out std_logic_vector(11 downto 0) -- Contém o valor de ângulo de 12 bits lido do AS5600   
    );
end entity;

architecture main of AS5600 is
    signal clk_div : integer 0 to clk_as5600 - 1 := 0;
begin
    -- Divisor de clock para 16MHz
    process(clk, rst)
    begin
        if rst = '1' then
            clk_div <= 0;
        elsif rising_edge(clk) then
            if clk_div = clk_as5600 - 1 then
                clk_div <= 0;
            else
                clk_div <= clk_div + 1;
            end if;
        end if;
    end process;
end architecture;