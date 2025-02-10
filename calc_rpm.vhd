--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_rpm is
    generic(
        clk_freq : integer := 100e6;
        polos : integer := 3
    ):
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
    signal estado_atual : std_logic_vector(2 downto 0);
    signal ultimo_estado : std_logic_vector(2 downto 0);
    signal contagem : integer := 0;
    signal contagem_transicao : integer := 0;
    signal rpm : integer := 0;
begin
    
    process(clk)
    begin
        if rst = '1' then
            contagem <= 0;
        elsif rising_edge(clk) then
            estado_hall <= hall_a & hall_b & hall_c;
            if ultimo_estado /= estado_atual then
                contagem_transicao <= contagem
                contagem <= 0;
                if contagem_transicao > 0 then
                    rpm <= (clk_freq * 60)/(contagem_transicao * (6 * polos));
                end if;
            else
                contagem <= contagem + 1;
            end if;

            ultimo_estado <= estado_atual;

        end if;
    end process;

    mensurado <= std_logic_vector(to_unsigned(rpm, 14));
    
end architecture;