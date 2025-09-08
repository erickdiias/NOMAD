-- =====================================================
-- Sistema UART Tx para comunicação FPGA-Arduino
-- Implementa transmissor UART a 9600 baud
-- =====================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        clk_freq  : integer := 50000000;    -- Frequência do clock em Hz
        baud_rate : integer := 9600         -- Taxa de transmissão em bps
    );
    port (
        clk, rst  : in  std_logic;               
        tx        : out  std_logic; -- Pino de transmissão UART
        tx_data   : in  std_logic_vector(7 downto 0); -- Dados a serem transmitidos
        tx_start  : in  std_logic; -- Sinal para iniciar a transmissão
        tx_busy   : out std_logic; -- Indica que a transmissão está em andamento
        tx_led    : out std_logic;
    );
end entity uart_tx;

architecture Behavioral of uart_tx is
    -- Parâmetros UART para 9600 baud @ 50MHz
    constant max_cycle : integer := clk_freq / baud_rate; -- Período de um bit em ciclos de clock
    signal shift_register : std_logic_vector(9 downto 0); -- Start bit + 8 bits de dados + Stop bit
    signal tx_loaded : boolean;
    signal tx_transf : boolean;

begin

    tx_process: process(clk, rst)
        variable i : integer range 0 to 9;
    begin
        if rst = '0' then
            shift_reg <= (others => '1'); -- Linha de transmissão inativa (idle)
            tx_loaded <= False;
            tx_busy <= '0';
            tx <= '1'; -- Linha de transmissão inativa (idle)
            tx_led <= '0';
            i := 0;
        elsif rising_edge(clk) then
            if tx_load = '0' then
                shift_reg <= '0' & tx_data & '1'; -- Start bit + dados + Stop bit
                tx_loaded <= True;
                tx_busy <= '1';
                tx_led <= '1';
            elsif tx_loaded then
                if tx_transf then
                    tx <= shift_register(0);
                    shift_register <= '1' & shift_register(9 downto 1); -- Desloca o registrador
                    if i = 9 then
                        tx_loaded <= False;
                        tx_busy <= '0';
                        tx <= '1'; -- Linha de transmissão inativa (idle)
                        tx_led <= '0';
                        i := 0;
                    else
                        i := i + 1;
                    end if;
                end if;
            end if;
        end if;
    end process tx_process;

    baud_gen: process(clk, rst)
        variable count : integer range 0 to max_cycle := 0;
    begin
        if rst = '0' then
            count := 0;
            tx_transf <= False;
        elsif rising_edge(clk) then
            if count = max_cycle - 1 then
                count := 0;
                tx_transf <= True;
            else
                count := count + 1;
                tx_transf <= False;
            end if;
        end if;
    end process baud_gen;

    
end architecture Behavioral;