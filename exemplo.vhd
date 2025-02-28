LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; -- velocidade do clock de entrada em Hz
    bus_clk   : INTEGER := 400_000);   -- velocidade do barramento I2C (SCL) em Hz
  PORT(
    clk       : IN     STD_LOGIC;                    -- clock do sistema
    reset_n   : IN     STD_LOGIC;                    -- reset ativo baixo
    ena       : IN     STD_LOGIC;                    -- comando de latência
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); -- endereço do escravo de destino
    rw        : IN     STD_LOGIC;                    -- '0' para escrita, '1' para leitura
    busy      : OUT    STD_LOGIC;                    -- indica que a transação está em progresso
    ack_error : BUFFER STD_LOGIC;                    -- flag de erro de reconhecimentoz
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); -- dados lidos do escravo
    sda       : INOUT  STD_LOGIC;                    -- linha de dados serial do barramento I2C
    scl       : INOUT  STD_LOGIC);                   -- linha de clock serial do barramento I2C
END i2c_master;

ARCHITECTURE logic OF i2c_master IS
  CONSTANT divider  :  INTEGER := (input_clk/bus_clk)/4; -- número de clocks em 1/4 ciclo do SCL
  TYPE machine IS(ready, start, rd, mstr_ack, stop); -- estados necessários para leitura
  SIGNAL state         : machine;                        -- máquina de estados
  SIGNAL data_clk      : STD_LOGIC;                      -- clock de dados para SDA
  SIGNAL data_clk_prev : STD_LOGIC;                      -- clock de dados durante o clock de sistema anterior
  SIGNAL scl_clk       : STD_LOGIC;                      -- SCL interno constante
  SIGNAL scl_ena       : STD_LOGIC := '0';               -- habilita o SCL interno para saída
  SIGNAL sda_int       : STD_LOGIC := '1';               -- SDA interno
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- endereço e leitura/escrita latched
  SIGNAL data_rx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- dados recebidos do escravo
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 7 := 7;      -- conta os bits na transação
  SIGNAL stretch       : STD_LOGIC := '0';               -- identifica se o escravo está esticando o SCL
BEGIN

  -- gerar o temporizador para o clock de barramento (scl_clk) e o clock de dados (data_clk)
  PROCESS(clk, reset_n)
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;  -- temporizador para geração de clock
  BEGIN
    IF(reset_n = '0') THEN                -- reset acionado
      stretch <= '0';
      count := 0;
    ELSIF(clk'EVENT AND clk = '1') THEN
      data_clk_prev <= data_clk;          -- armazena o valor anterior do clock de dados
      IF(count = divider*4-1) THEN        -- fim do ciclo de temporização
        count := 0;                       -- reseta o temporizador
      ELSIF(stretch = '0') THEN           -- esticamento do clock pelo escravo não detectado
        count := count + 1;               -- continua a contagem para a geração de clock
      END IF;
      CASE count IS
        WHEN 0 TO divider-1 =>            -- primeiro 1/4 ciclo de clock
          scl_clk <= '0';
          data_clk <= '0';
        WHEN divider TO divider*2-1 =>    -- segundo 1/4 ciclo de clock
          scl_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 TO divider*3-1 =>  -- terceiro 1/4 ciclo de clock
          scl_clk <= '1';                 -- libera o SCL
          IF(scl = '0') THEN              -- detecta se o escravo está esticando o clock
            stretch <= '1';
          ELSE
            stretch <= '0';
          END IF;
          data_clk <= '1';
        WHEN OTHERS =>                    -- último 1/4 ciclo de clock
          scl_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;

  -- máquina de estados para leitura
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 -- reset acionado
      state <= ready;                      -- retorna ao estado inicial
      busy <= '1';                         -- indica que não está disponível
      scl_ena <= '0';                      -- define o SCL como alta impedância
      sda_int <= '1';                      -- define o SDA como alta impedância
      ack_error <= '0';                    -- limpa a flag de erro de reconhecimento
      bit_cnt <= 7;                        -- reinicia o contador de bits
      data_rd <= "00000000";               -- limpa a porta de dados lidos
    ELSIF(clk'EVENT AND clk = '1') THEN
      IF(data_clk = '1' AND data_clk_prev = '0') THEN  -- borda de subida do clock de dados
        CASE state IS
          WHEN ready =>                      -- estado ocioso
            IF(ena = '1') THEN               -- transação solicitada
              busy <= '1';                   -- marca como ocupado
              addr_rw <= addr & rw;          -- coleta o endereço e comando do escravo solicitado
              state <= start;                -- vai para o bit de start
            ELSE                             -- permanece ocioso
              busy <= '0';                   -- desmarca como ocupado
              state <= ready;                -- permanece ocioso
            END IF;
          WHEN start =>                      -- bit de start da transação
            busy <= '1';                     -- retoma ocupado
            sda_int <= addr_rw(bit_cnt);     -- coloca o primeiro bit de endereço na linha de dados
            state <= rd;                     -- vai para a leitura
          WHEN rd =>                         -- byte de leitura da transação
            busy <= '1';                     -- retoma ocupado
            IF(bit_cnt = 0) THEN             -- leitura do byte finalizada
              IF(ena = '1' AND addr_rw = addr & rw) THEN  -- continua com outra leitura no mesmo endereço
                sda_int <= '0';              -- reconhece que o byte foi recebido
              ELSE                           -- interrompe ou continua com uma escrita
                sda_int <= '1';              -- envia um não reconhecimento (antes do stop)
              END IF;
              bit_cnt <= 7;                  -- reseta o contador de bits para os estados de "byte"
              data_rd <= data_rx;            -- coloca os dados recebidos na saída
              state <= mstr_ack;             -- vai para o reconhecimento do mestre
            ELSE                             -- próximo ciclo de clock no estado de leitura
              bit_cnt <= bit_cnt - 1;        -- acompanha os bits da transação
              state <= rd;                   -- continua lendo
            END IF;
          WHEN mstr_ack =>                   -- bit de reconhecimento do mestre após a leitura
            IF(ena = '1') THEN               -- continua a transação
              busy <= '0';                   -- transação aceita e dados disponíveis no barramento
              state <= stop;                 -- vai para o bit de stop
            ELSE                             -- completa a transação
              state <= stop;                 -- vai para o bit de stop
            END IF;
          WHEN stop =>                       -- bit de stop da transação
            busy <= '0';                     -- desmarca como ocupado
            state <= ready;                  -- vai para o estado ocioso
        END CASE;    
      ELSIF(data_clk = '0' AND data_clk_prev = '1') THEN  -- borda de descida do clock de dados
        CASE state IS
          WHEN start =>                  
            IF(scl_ena = '0') THEN                  -- iniciando nova transação
              scl_ena <= '1';
            END IF;
        END CASE;
      END IF;
    END IF;
  END PROCESS;

END logic;
