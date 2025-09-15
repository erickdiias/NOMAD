-- Tacômetro VHDL
-- Descrição: Registro de leitura de velocidade com 3 sensor de efeito hall
-- Autor: Erick S. Dias
-- Data: 12/09/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegisterRead is
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

end entity;

architecture rtl of RegisterRead is

    constant num_trans_ele := 2 * num_hall; -- Número de transições elétricas por volta, um sensor hall varia entre on/off(2 transições)
    constant num_trans_mec := num_trans_ele * par_polos; -- Número de transições mecanicas por volta

    constant janela_ciclos : integer := (freq_clk / 1000) * time_window; -- Janela de tempo em ciclos de clock

    -- Estados válidos dos sensores Hall para motor BLDC
    type hall_state_array is array (0 to 5) of std_logic_vector(2 downto 0);
    constant hall_state : hall_state_array := ("001", "011", "010", "110", "100", "101");
    
    -- Sinais internos
    signal hall_anterior, hall_atual : std_logic_vector(num_hall-1 downto 0) := (others => '0'); -- Estado anterior dos sensores Hall // Estado atual dos sensores Hall
    signal cont_trans, cont_tempo  : unsigned(31 downto 0) := (others => '0'); -- Contador de transições // Contador de tempo

    signal hall_sync1, hall_sync2 : std_logic_vector(num_hall-1 downto 0) := (others => '0'); -- Sinais sincronizados dos sensores Hall (2 FFs)

begin

    ------------------------------------------------------------------------
    -- Sincronização dos sensores Hall (2 FFs para evitar metastabilidade)
    ------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            hall_sync1 <= sensor_hall;  -- 1º estágio
            hall_sync2 <= hall_sync1;   -- 2º estágio (usado no resto do código)
        end if;
    end process;

    ------------------------------------------------------------------------
    -- Lógica principal do tacômetro
    ------------------------------------------------------------------------
    process(clk)
        variable rpm_calc : integer;
        variable hall_valido : boolean;
    begin
        if rising_edge(clk) then
            hall_valido := false; -- Reset varialvel a cada ciclo
            hall_atual := hall_sync2; -- Atualiza o estado atual dos sensores Hall

            -- Verifica se houve mudança no estado dos sensores Hall
            if hall_atual /= hall_anterior then
                -- Verifica se a nova combinação é válida
                for i in hall_state'range loop
                    if hall_atual = hall_state(i) then
                        hall_valido := true;
                    end if;
                end loop;
                -- Se a combinação for válida, incrementa o contador de transições           
                if hall_valido then
                    cont_trans <= cont_trans + 1;
                end if;
            end if;
            -- Atualiza o estado anterior
            hall_anterior <= hall_atual;
                    
            -- Controle de janela de tempo
            if cont_tempo < to_unsigned(janela_ciclos-1, cont_tempo'length) then
                cont_tempo <= cont_tempo + 1;
            else
                cont_tempo <= (others => '0'); -- Reseta o contador de tempo

                -- Calcula RPM:
                -- RPM = (Número de transições / Número de transições por volta) * (60 segundos / janela de tempo em segundos)
                if cont_trans > 0 then
                    rpm_calc := (to_integer(cont_trans) * (60 * 1000)) / (num_trans_mec * time_window); -- 60 s/min, janela em ms). Isso está ok.
                else
                    rpm_calc := 0;
                end if;

                regout <= std_logic_vector(to_unsigned(rpm_calc, regout'length)); -- Atualiza a saída do registro
                cont_trans <= (others => '0'); -- Reseta o contador de transições
            end if;
        end if;
    end process;
    
end architecture rtl;