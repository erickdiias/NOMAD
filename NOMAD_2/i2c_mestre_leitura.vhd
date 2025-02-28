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
        registrador_addr: std_logic_vector(7 downto 0) := "00001100" -- "0x0C" Endereço do registrador para ler os dados de ângulo (no caso, no AS5600)
    );
    port(
        clk             : in std_logic; -- Clock de entrada da FPGA
        rst             : in std_logic; -- Reset (ativo baixo)
        ena           : in  std_logic; -- Inicia a comunicação quando em nível alto
        ready           : out std_logic; -- Indica que o módulo está pronto para iniciar
        done            : out std_logic; -- Indica que a leitura foi concluída
        angle           : out std_logic_vector(11 downto 0); -- Contém o valor de ângulo de 12 bits lido do AS5600   
        scl             : out std_logic; -- linha de dados serial do barramento I2C
        sda             : inout std_logic -- linha de clock serial do barramento I2C
    );
end entity;

architecture main of i2c_mestre_leitura is
    constant clk_div    : integer := (input_clk/bus_clk) / 4; -- número de clocks em 1/4 de ciclo do SCL
    type maquina is (ready, start, rd, mstr_ack, stop); -- estados necessários para leitura
    signal estado : maquina; -- máquina de estados
    signal data_clk      : std_logic;                      -- clock de dados para SDA
    signal data_clk_prev : std_logic;                      -- clock de dados durante o clock de sistema anterior
    signal scl_clk       : std_logic;                      -- SCL interno constante
    signal scl_ena       : std_logic := '0';               -- habilita o SCL interno para saída
    signal sda_int       : std_logic := '1';               -- SDA interno
    signal addr_rw       : std_logic_vector(7 downto 0);   -- endereço e leitura/escrita latched
    signal data_rx       : std_logic_vector(7 downto 0);   -- dados recebidos do escravo
    signal bit_cnt       : integer range 0 to 7 := 7;      -- conta os bits na transação
    signal stretch       : std_logic := '0';               -- identifica se o escravo está esticando o SCL

begin
    -- gerar o temporizador para o clock de barramento (scl_clk) e o clock de dados (data_clk)
    process(clk, rst)
        variable contagem  :  integer range 0 to clk_div*4;  -- temporizador para geração de clock
    begin
        if(rst = '1') then                -- reset acionado
            stretch <= '0';
            contagem := 0;
        elsif(rising_edge(clk) and clk = '1') then
            data_clk_prev <= data_clk;          -- armazena o valor anterior do clock de dados
            if(contagem = clk_div*4-1) then        -- fim do ciclo de temporização
            contagem := 0;                       -- reseta o temporizador
            elsif(stretch = '0') then           -- esticamento do clock pelo escravo não detectado
            contagem := contagem + 1;               -- continua a contagem para a geração de clock
            end if;
            case contagem IS
            when 0 to clk_div-1 =>            -- primeiro 1/4 ciclo de clock
                scl_clk <= '0';
                data_clk <= '0';
            when clk_div to clk_div*2-1 =>    -- segundo 1/4 ciclo de clock
                scl_clk <= '0';
                data_clk <= '1';
            when clk_div*2 to clk_div*3-1 =>  -- terceiro 1/4 ciclo de clock
                scl_clk <= '1';                 -- libera o SCL
                if(scl = '0') then              -- detecta se o escravo está esticando o clock
                stretch <= '1';
                else
                stretch <= '0';
                end if;
                data_clk <= '1';
            when others =>                    -- último 1/4 ciclo de clock
                scl_clk <= '1';
                data_clk <= '0';
            end case;
        end if;
    end process;
end architecture;