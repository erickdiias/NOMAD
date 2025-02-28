-- Descricao: 
--
-- Autor: Erick S. Dias
-- Ultima atualizacao: 26/02/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_mestre_leitura is
    generic(
        input_clk       : integer := 100_000_000; -- velocidade do clock de entrada em Hz
        bus_clk         : integer := 3_125_000; -- Velocidade em que o barramento i2c (scl) será executado em Hz. Modo de alta velocidade: 3,4 MHz
        slave_addr      : std_logic_vector(6 downto 0) := "0110110"; -- "0x36" Endereço do dispositivo I2C (no caso, o AS5600)
        register_addr   : std_logic_vector(7 downto 0) := "00001100" -- "0x0C" Endereço do registrador para ler os dados de ângulo (no caso, no AS5600)
    );
    port(
        clk             : in std_logic; -- Clock de entrada da FPGA
        rst             : in std_logic; -- Reset (ativo baixo)
        start           : in  std_logic; -- Inicia a comunicação quando em nível alto
        ready           : out std_logic; -- Indica que o módulo está pronto para iniciar
        done            : out std_logic; -- Indica que a leitura foi concluída
        angle           : out std_logic_vector(11 downto 0); -- Contém o valor de ângulo de 12 bits lido do AS5600   
        scl             : inout std_logic; -- linha de dados serial do barramento I2C
        sda             : inout std_logic -- linha de clock serial do barramento I2C
    );
end entity;

architecture main of i2c_mestre_leitura is
    constant clk_div    : integer := (input_clk/bus_clk) / 4;

    signal stretch      : std_logic := '0'; -- identifica se o escravo está esticando o SCLz
    signal data_clk     : std_logic; -- clock de dados para SDAz
    signal data_clk_prev : std_logic; -- clock de dados durante o clock de sistema anterior

begin
    -- gerar o temporizador para o clock de barramento (scl_clk) e o clock de dados (data_clk)
    process(clk, rst)
        variable contagem : integer range 0 to clk_div * 4;
    begin
        if rst = '1' then
            stretch <= '0';
            contagem := 0;
        elsif rising_edge(clk) and clk = '1' then
            data_clk_prev <= data_clk;          -- armazena o valor anterior do clock de dados
            if contagem = clk_div*4 - 1 then
                contagem := 0;
            elsif stretch = '0' then
                contagem <= contagem + 1;
            end if;
        case contagem is
            when 0
        end if;
    end process;
end architecture;