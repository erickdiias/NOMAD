LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; -- velocidade do clock de entrada fornecido pela lógica do usuário em Hz
    bus_clk   : INTEGER := 400_000;    -- velocidade do barramento I2C (SCL) em Hz
    addr      : std_logic_vector(6 downto 0) := "0110110";
    data_rd

    );   
  PORT(
    clk       : IN     STD_LOGIC;                    -- clock do sistema
    reset_n   : IN     STD_LOGIC;                    -- reset ativo baixo
    ena       : IN     STD_LOGIC;                    -- trava o comando
    rw        : IN     STD_LOGIC;                    -- '0' para escrever, '1' para ler
    busy      : OUT    STD_LOGIC;                    -- indica que a transação está em progresso
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); -- dados lidos do escravo
    ack_error : BUFFER STD_LOGIC;                    -- flag de erro de reconhecimento do escravo
    sda       : INOUT  STD_LOGIC;                    -- dado serial de saída do barramento I2C
    scl       : INOUT  STD_LOGIC);                   -- clock serial de saída do barramento I2C
END i2c_master;

ARCHITECTURE logic OF i2c_master IS
  CONSTANT divider  :  INTEGER := (input_clk/bus_clk)/4; -- número de clocks em 1/4 de ciclo do SCL
  TYPE machine IS(ready, start, command, slv_ack1, rd, slv_ack2, mstr_ack, stop); -- estados necessários
  SIGNAL state         : machine;                        -- máquina de estados
  SIGNAL data_clk      : STD_LOGIC;                      -- clock de dados para SDA
  SIGNAL data_clk_prev : STD_LOGIC;                      -- clock de dados do ciclo de clock anterior
  SIGNAL scl_clk       : STD_LOGIC;                      -- SCL interno que está sempre em execução
  SIGNAL scl_ena       : STD_LOGIC := '0';               -- habilita o SCL interno para saída
  SIGNAL sda_int       : STD_LOGIC := '1';               -- SDA interno
  SIGNAL sda_ena_n     : STD_LOGIC;                      -- habilita o SDA interno para saída
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- endereço e comando de leitura/escrita latched
  SIGNAL data_rx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   -- dados recebidos do escravo
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 7 := 7;      -- controla o número do bit na transação
  SIGNAL stretch       : STD_LOGIC := '0';               -- identifica se o escravo está esticando o SCL
BEGIN

  -- gera o timing para o clock do barramento (scl_clk) e o clock de dados (data_clk)
  PROCESS(clk, reset_n)
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;  -- timing para a geração do clock
  BEGIN
    IF(reset_n = '0') THEN                -- reset assertado
      stretch <= '0';
      count := 0;
    ELSIF(clk'EVENT AND clk = '1') THEN
      data_clk_prev <= data_clk;          -- armazena o valor anterior do clock de dados
      IF(count = divider*4-1) THEN        -- fim do ciclo de timing
        count := 0;                       -- reset do temporizador
      ELSIF(stretch = '0') THEN           -- estiramento de clock do escravo não detectado
        count := count + 1;               -- continua o timing da geração do clock
      END IF;
      CASE count IS
        WHEN 0 TO divider-1 =>            -- primeiro 1/4 do ciclo de clock
          scl_clk <= '0';
          data_clk <= '0';
        WHEN divider TO divider*2-1 =>    -- segundo 1/4 do ciclo de clock
          scl_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 TO divider*3-1 =>  -- terceiro 1/4 do ciclo de clock
          scl_clk <= '1';                 -- libera o SCL
          IF(scl = '0') THEN              -- detecta se o escravo está esticando o clock
            stretch <= '1';
          ELSE
            stretch <= '0';
          END IF;
          data_clk <= '1';
        WHEN OTHERS =>                    -- último 1/4 do ciclo de clock
          scl_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;

  -- máquina de estados e leitura do SDA durante o SCL baixo (na borda de subida do data_clk)
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 -- reset assertado
      state <= ready;                      -- retorna para o estado inicial
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
            busy <= '1';                     -- retoma ocupado caso no modo contínuo
            sda_int <= addr_rw(bit_cnt);     -- coloca o primeiro bit de endereço na linha de dados
            state <= command;                -- vai para o comando
          WHEN command =>                    -- byte de endereço e comando da transação
            IF(bit_cnt = 0) THEN             -- comando transmitido com sucesso
              sda_int <= '1';                -- libera o SDA para o reconhecimento do escravo
              bit_cnt <= 7;                  -- reseta o contador de bits para os estados de "byte"
              state <= slv_ack1;             -- vai para o reconhecimento do escravo (comando)
            ELSE                             -- próximo ciclo do clock no estado de comando
              bit_cnt <= bit_cnt - 1;        -- acompanha os bits da transação
              sda_int <= addr_rw(bit_cnt-1); -- escreve o bit de endereço/comando no barramento
              state <= command;              -- continua com o comando
            END IF;
          WHEN slv_ack1 =>                   -- bit de reconhecimento do escravo (comando)
            IF(addr_rw(0) = '1') THEN        -- comando de leitura
              sda_int <= '1';                -- libera o SDA para dados de entrada
              state <= rd;                   -- vai para o byte de leitura
            END IF;
          WHEN rd =>                         -- byte de leitura da transação
            busy <= '1';                     -- retoma ocupado caso no modo contínuo
            IF(bit_cnt = 0) THEN             -- leitura do byte finalizada
              IF(ena = '1' AND addr_rw = addr & rw) THEN  -- continua com outra leitura no mesmo endereço
                sda_int <= '0';              -- reconhece que o byte foi recebido
              ELSE                           -- interrompe ou continua com uma escrita
                sda_int <= '1';              -- envia um não reconhecimento (antes do stop ou start repetido)
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
