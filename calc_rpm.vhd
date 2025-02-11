--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_rpm is
    generic(
        clk_freq : integer := 100_000_000;
        pares_polos : integer := 2
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        hall_a : in std_logic;
        hall_b : in std_logic;
        hall_c : in std_logic;
        mensurado : out std_logic_vector(13 downto 0)
    );
end entity;

architecture main of calc_rpm is
    signal estado_atual         : std_logic_vector(2 downto 0);
    signal ultimo_estado        : std_logic_vector(2 downto 0) := "000";
    signal contagem             : integer := 0;
    signal contagem_transicao   : integer := 1;  -- Evita divisão por zero
    signal rpm                  : integer := 0;
    constant max_contagem       : integer := clk_freq / 2;  -- Timeout ajustado para resposta mais rápida
begin
    
    process(clk, rst)
    begin
        if rst = '1' then
            contagem <= 0;
            contagem_transicao <= 1;  -- O valor 1 evita divisão por zero
            rpm <= 0;
            ultimo_estado <= (others => '0');

        elsif rising_edge(clk) then
            estado_atual <= hall_a & hall_b & hall_c;

            if ultimo_estado /= estado_atual then
                if contagem > 0 then
                    contagem_transicao <= contagem;
                end if;
                contagem <= 0;

                if contagem_transicao > 0 then
                    rpm <= (clk_freq * 60) / (contagem_transicao * 6 * pares_polos);
                end if;
            else
                contagem <= contagem + 1;
            end if;

            -- Se não houver transições por muito tempo, definir RPM como zero
            if contagem >= max_contagem then
                rpm <= 0;
            end if;

            ultimo_estado <= estado_atual;
        end if;
    end process;

    -- Proteção contra valores negativos
    mensurado <= std_logic_vector(to_unsigned(rpm, 14)) when rpm > 0 else (others => '0');

end architecture;
