--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Mensurado is
    generic(
        clk_freq : integer := 100_000_000;
        pares_polos : integer := 7
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        sensor_hall : in std_logic_vector(2 downto 0);
        mensurado : out std_logic_vector(13 downto 0)
    );
end entity;

architecture main of Mensurado is

    constant max_contagem       : integer := clk_freq / 2;

    signal estado_atual         : std_logic_vector(2 downto 0);
    signal ultimo_estado        : std_logic_vector(2 downto 0) := "000";
    
    signal contagem             : integer := 0;
    signal contagem_transicao   : integer := 1;  -- O valor 1 evita divisão por zero no início
    signal rpm                  : integer := 0;
    
begin
    
    process(clk, rst)
    begin
        if rst = '1' then
            contagem <= 0;
            contagem_transicao <= 1;  -- O valor 1 evita divisão por zero
            rpm <= 0;
            ultimo_estado <= (others => '0');

        elsif rising_edge(clk) then
            estado_atual <= sensor_hall;

            if ultimo_estado /= estado_atual then
                contagem_transicao <= contagem;
                contagem <= 0;

                if contagem_transicao > 1 then
                    rpm <= ((clk_freq / (6 * pares_polos)) * (60 / contagem_transicao));
                else
                    rpm <= 0;
                end if;
            else
                contagem <= contagem + 1;
            end if;

            -- Se não houver transições por muito tempo
            if contagem >= max_contagem then
                rpm <= 0;
            end if;

            ultimo_estado <= estado_atual;
        end if;
    end process;

    mensurado <= std_logic_vector(to_unsigned(rpm, 14)) when rpm > 0 else (others => '0');

end architecture;
