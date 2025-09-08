-- =====================================================
-- Sistema UART para comunicação FPGA-Arduino
-- Implementa receptor e transmissor UART a 9600 baud
-- =====================================================

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

-- Entidade principal do sistema
entity protocol_uart is
    Port ( 
        clk     : in  STD_LOGIC;  -- Clock da FPGA
        reset   : in  STD_LOGIC;  -- Reset ativo alto
        uart_rx : in  STD_LOGIC;  -- Linha RX
        uart_tx : out STD_LOGIC;  -- Linha TX

        led_rx  : out STD_LOGIC;  -- LED indica recepção
        led_tx  : out STD_LOGIC   -- LED indica transmissão
    );
end protocol_uart;

architecture Behavioral of protocol_uart is

    -- Parâmetros UART para 9600 baud @ 50MHz
    constant BAUD_RATE    : integer := 9600;
    constant CLK_FREQ     : integer := 50000000;
    constant BAUD_DIVISOR : integer := CLK_FREQ / BAUD_RATE;
    
    -- Sinais internos
    signal baud_tick      : std_logic := '0';
    signal baud_counter   : integer range 0 to BAUD_DIVISOR-1;
    
    -- Sinais do receptor UART
    signal rx_data        : std_logic_vector(7 downto 0);
    signal rx_start       : std_logic;
    signal rx_busy        : std_logic;
    
    -- Sinais do transmissor UART
    signal tx_data        : std_logic_vector(7 downto 0);
    signal tx_start       : std_logic;
    signal tx_busy        : std_logic;
    
    -- Processamento de dados
    signal setpoint       : unsigned(15 downto 0) := (others => '0');
    signal process_value  : unsigned(15 downto 0) := (others => '0');
    signal sp_buffer      : std_logic_vector(15 downto 0);
    signal byte_counter   : integer range 0 to 3 := 0;
    
    -- Estados da máquina de controle
    type state_type is (IDLE, RECEIVING_SP, PROCESSING, SENDING_PV);
    signal current_state  : state_type := IDLE;
    

begin

    -- =====================================================
    -- Gerador de Baud Rate
    -- =====================================================
    baud_rate_gen: process(clk, reset)
    begin
        if reset = '1' then
            baud_counter <= 0;
            baud_tick <= '0';
        elsif rising_edge(clk) then
            if baud_counter = BAUD_DIVISOR-1 then
                baud_counter <= 0;
                baud_tick <= '1';
            else
                baud_counter <= baud_counter + 1;
                baud_tick <= '0';
            end if;
        end if;
    end process;

    -- =====================================================
    -- Receptor UART
    -- =====================================================
    uart_rx_inst: entity work.uart_receiver
        port map (
            clk => clk,
            reset => reset,
            baud_tick => baud_tick,
            rx_line => uart_rx,
            data_out => rx_data,
            data_valid => rx_start      ,
            busy => rx_busy
        );

    -- =====================================================
    -- Transmissor UART
    -- =====================================================
    uart_tx_inst: entity work.uart_transmitter
        port map (
            clk => clk,
            reset => reset,
            baud_tick => baud_tick,
            data_in => tx_data,
            start => tx_start,
            tx_line => uart_tx,
            busy => tx_busy
        );

    -- =====================================================
    -- Máquina de Estados Principal
    -- =====================================================
    main_fsm: process(clk, reset)
        variable tx_byte_count : integer range 0 to 3 := 0;
    begin
        if reset = '1' then
            current_state <= IDLE;
            setpoint <= (others => '0');
            byte_counter <= 0;
            tx_start <= '0';
            tx_byte_count := 0;
        elsif rising_edge(clk) then
            
            case current_state is
                
                when IDLE =>
                    led_rx <= '0';
                    led_tx <= '0';
                    tx_start <= '0';
                    
                    if rx_start      = '1' then
                        -- Protocolo: recebe comando primeiro
                        if rx_data = x"53" then -- 'S' para Setpoint
                            current_state <= RECEIVING_SP;
                            byte_counter <= 0;
                            led_rx <= '1';
                        end if;
                    end if;
                
                when RECEIVING_SP =>
                    if rx_start      = '1' then
                        case byte_counter is
                            when 0 => 
                                sp_buffer(15 downto 8) <= rx_data;
                                byte_counter <= 1;
                            when 1 => 
                                sp_buffer(7 downto 0) <= rx_data;
                                setpoint <= unsigned(sp_buffer(15 downto 8) & rx_data);
                                current_state <= PROCESSING;
                                byte_counter <= 0;
                            when others =>
                                current_state <= IDLE;
                        end case;
                    end if;
                
                when PROCESSING =>
                    -- Aguarda um ciclo para processar
                    current_state <= SENDING_PV;
                    tx_byte_count := 0;
                    led_tx <= '1';
                
                when SENDING_PV =>
                    if tx_busy = '0' and tx_start = '0' then
                        case tx_byte_count is
                            when 0 => 
                                tx_data <= x"50"; -- 'P' para Process Value
                                tx_start <= '1';
                                tx_byte_count := 1;
                            when 1 => 
                                tx_data <= std_logic_vector(process_value(15 downto 8));
                                tx_start <= '1';
                                tx_byte_count := 2;
                            when 2 => 
                                tx_data <= std_logic_vector(process_value(7 downto 0));
                                tx_start <= '1';
                                tx_byte_count := 3;
                            when 3 => 
                                tx_data <= x"0A"; -- Line Feed
                                tx_start <= '1';
                                current_state <= IDLE;
                                tx_byte_count := 0;
                        end case;
                    else
                        tx_start <= '0';
                    end if;
                    
            end case;
        end if;
    end process;

end Behavioral;

-- =====================================================
-- RECEPTOR UART
-- =====================================================
library ieee;
use ieee.std_logic_1164.ALL;

entity uart_receiver is
    Port ( 
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        baud_tick  : in  STD_LOGIC;
        rx_line    : in  STD_LOGIC;
        data_out   : out STD_LOGIC_VECTOR(7 downto 0);
        data_valid : out STD_LOGIC;
        busy       : out STD_LOGIC
    );
end uart_receiver;

architecture Behavioral of uart_receiver is
    type rx_state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal rx_state : rx_state_type := IDLE;
    signal bit_counter : integer range 0 to 8 := 0;
    signal data_reg : std_logic_vector(7 downto 0);
    signal rx_sync : std_logic_vector(2 downto 0);
begin

    -- Sincronização do sinal RX
    sync_process: process(clk, reset)
    begin
        if reset = '1' then
            rx_sync <= "111";
        elsif rising_edge(clk) then
            rx_sync <= rx_sync(1 downto 0) & rx_line;
        end if;
    end process;

    -- Máquina de estados do receptor
    rx_process: process(clk, reset)
    begin
        if reset = '1' then
            rx_state <= IDLE;
            bit_counter <= 0;
            data_out <= (others => '0');
            data_valid <= '0';
            busy <= '0';
        elsif rising_edge(clk) then
            data_valid <= '0';
            
            if baud_tick = '1' then
                case rx_state is
                    when IDLE =>
                        busy <= '0';
                        if rx_sync(2) = '0' then -- Start bit detectado
                            rx_state <= START_BIT;
                            busy <= '1';
                        end if;
                    
                    when START_BIT =>
                        if rx_sync(2) = '0' then
                            rx_state <= DATA_BITS;
                            bit_counter <= 0;
                        else
                            rx_state <= IDLE; -- Falso start bit
                        end if;
                    
                    when DATA_BITS =>
                        data_reg(bit_counter) <= rx_sync(2);
                        if bit_counter = 7 then
                            rx_state <= STOP_BIT;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    
                    when STOP_BIT =>
                        if rx_sync(2) = '1' then
                            data_out <= data_reg;
                            data_valid <= '1';
                        end if;
                        rx_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;

-- =====================================================
-- TRANSMISSOR UART
-- =====================================================
library ieee;
use ieee.std_logic_1164.ALL;

entity uart_transmitter is
    Port ( 
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        baud_tick : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
        start     : in  STD_LOGIC;
        tx_line   : out STD_LOGIC;
        busy      : out STD_LOGIC
    );
end uart_transmitter;

architecture Behavioral of uart_transmitter is
    type tx_state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal tx_state : tx_state_type := IDLE;
    signal bit_counter : integer range 0 to 8 := 0;
    signal data_reg : std_logic_vector(7 downto 0);
begin

    tx_process: process(clk, reset)
    begin
        if reset = '1' then
            tx_state <= IDLE;
            bit_counter <= 0;
            tx_line <= '1';
            busy <= '0';
        elsif rising_edge(clk) then
            
            case tx_state is
                when IDLE =>
                    tx_line <= '1';
                    busy <= '0';
                    if start = '1' then
                        data_reg <= data_in;
                        tx_state <= START_BIT;
                        busy <= '1';
                    end if;
                
                when START_BIT =>
                    if baud_tick = '1' then
                        tx_line <= '0'; -- Start bit
                        tx_state <= DATA_BITS;
                        bit_counter <= 0;
                    end if;
                
                when DATA_BITS =>
                    if baud_tick = '1' then
                        tx_line <= data_reg(bit_counter);
                        if bit_counter = 7 then
                            tx_state <= STOP_BIT;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    end if;
                
                when STOP_BIT =>
                    if baud_tick = '1' then
                        tx_line <= '1'; -- Stop bit
                        tx_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;