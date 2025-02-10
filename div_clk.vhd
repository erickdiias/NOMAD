--
--
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity div_clk is
    generic(
        freq_clk : integer := 100e6
    );
    port(
        clk : in std_logic;
        clk_out : out std_logic
    );
end entity;

architecture main of div_clk is
    signal contagem : integer := 0;
    signal clk_out_int : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if contagem = (freq_clk / 2) then
                contagem <= 0;
                clk_out_int <= not clk_out_int;
            else
                contagem <= contagem + 1;
            end if;
        end if;
    end process;

    clk_out <= clk_out_int;

end architecture;