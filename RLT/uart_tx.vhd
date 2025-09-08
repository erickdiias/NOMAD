-- =====================================================
-- UART Tx para FPGA-Arduino usando FSM
-- 9600 baud @ 50MHz
-- =====================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        clk_freq  : integer := 50000000; -- Clock da FPGA
        baud_rate : integer := 9600      -- Taxa UART
    );
    port (
        clk, rst : in  std_logic; 
        tx       : out std_logic;        -- Pino de saída UART_Tx

        tx_data  : in  std_logic_vector(7 downto 0); -- Byte a transmitir
        tx_start : in  std_logic;        -- Pulso para iniciar transmissão

        tx_busy  : out std_logic         -- Indica transmissão em andamento (LED)
    );
end entity;

architecture fsm of uart_tx is

    -- Parâmetro de baud
    constant max_cycle : integer := clk_freq / baud_rate;

    -- FSM States
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state    : state_type := IDLE;

    -- Contadores
    signal baud_cnt : integer range 0 to max_cycle-1 := 0;
    signal bit_cnt  : integer range 0 to 7 := 0;

    -- Registradores internos
    signal tx_reg   : std_logic := '1';
    signal busy_reg : std_logic := '0';

begin
    -- Saídas
    tx <= tx_reg;
    tx_busy <= busy_reg;

    -- Máquina de estados do transmissor UART
    tx_process: process(clk, rst)
    begin
        if rst = '1' then
            state    <= IDLE;
            tx_reg   <= '1';
            busy_reg <= '0';
            baud_cnt <= 0;
            bit_cnt  <= 0;
        elsif rising_edge(clk) then
            case state is

                when IDLE =>
                    tx_reg <= '1';
                    busy_reg <= '0';
                    if tx_start = '1' then
                        state <= START_BIT;
                        busy_reg <= '1';
                        baud_cnt <= 0;
                        bit_cnt  <= 0;
                    end if;

                when START_BIT =>
                    tx_reg <= '0'; -- Start bit
                    if baud_cnt = max_cycle-1 then
                        baud_cnt <= 0;
                        state <= DATA_BITS;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when DATA_BITS =>
                    tx_reg <= tx_data(bit_cnt);
                    if baud_cnt = max_cycle-1 then
                        baud_cnt <= 0;
                        if bit_cnt = 7 then
                            state <= STOP_BIT;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

                when STOP_BIT =>
                    tx_reg <= '1'; -- Stop bit
                    if baud_cnt = max_cycle-1 then
                        baud_cnt <= 0;
                        state <= IDLE;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;

            end case;
        end if;
    end process;

end architecture;
