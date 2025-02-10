library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin2bcd is
    port(
        bin_14bits : in std_logic_vector(13 downto 0);
        bcd_16bits : out std_logic_vector(15 downto 0)
    );
end entity;

architecture main of bin2bcd is
begin
    process(bin_14bits)
        variable bin_temp : unsigned(13 downto 0);
        variable bcd_temp : unsigned(15 downto 0) := (others => '0');
    begin
        bin_temp := unsigned(bin_14bits);
        bcd_temp := (others => '0');

        for i in 0 to 13 loop
            -- Ajusta os dígitos BCD antes do deslocamento
            if bcd_temp(15 downto 12) > 4 then
                bcd_temp(15 downto 12) := bcd_temp(15 downto 12) + 3;
            end if;
            if bcd_temp(11 downto 8) > 4 then
                bcd_temp(11 downto 8) := bcd_temp(11 downto 8) + 3;
            end if;
            if bcd_temp(7 downto 4) > 4 then
                bcd_temp(7 downto 4) := bcd_temp(7 downto 4) + 3;
            end if;
            if bcd_temp(3 downto 0) > 4 then
                bcd_temp(3 downto 0) := bcd_temp(3 downto 0) + 3;
            end if;

            -- Desloca os bits para a esquerda
            bcd_temp := (bcd_temp(14 downto 0) & bin_temp(13));
            bin_temp := (bin_temp(12 downto 0) & '0');
        end loop;

        bcd_16bits <= std_logic_vector(bcd_temp);
    end process;
end architecture;
