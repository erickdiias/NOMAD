-- Tacômetro VHDL
-- Descrição: Registro de leitura de velocidade com 3 sensor de efeito hall
-- Autor: Erick S. Dias
-- Data: 12/09/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_read is
    generic(
        freq_clk : integer := 100_000_000; -- Clock da FPGA (Hz)
        num_hall : integer := 3;     -- Número de sensores Hall
        par_polos : integer := 7;    -- Número de polos do motor

        time_window : integer := 100; -- Janela de tempo para contagem de pulsos (ms)
    );
    port(
        clk : in std_logic;
        sensor_hall : in std_logic_vector(num_hall-1 downto 0);
        regout : out std_logic_vector(15 downto 0)
    );

end entity register_read;

architecture rtl of register_read is

    constant num_trans_ele := 2 * num_hall; -- Número de transições elétricas por volta, um sensor hall varia entre on/off(2 transições)
    constant num_trans_mec := num_trans_ele * par_polos; -- Número de transições mecanicas por volta

    constant janela_ciclos : integer := (freq_clk / 1000) * time_window; -- Janela de tempo em ciclos de clock

    -- Estados válidos dos sensores Hall para motor BLDC
    type hall_state_array is array (0 to 5) of std_logic_vector(2 downto 0);
    constant hall_state : hall_state_array := ("001", "011", "010", "110", "100", "101");
    

begin
    
end architecture rtl;