-- Converte binário (16 bits) para BCD 4 dígitos
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Bin2Bcd is
    port(
        bin : in  std_logic_vector(15 downto 0);
        bcd : out std_logic_vector(15 downto 0)  -- 4 nibbles: milhar, centena, dezena, unidade
    );
end entity Bin2Bcd;

architecture rtl of Bin2Bcd is
begin
    process(bin)
        variable bin_var : unsigned(15 downto 0);
        variable bcd_var : unsigned(15 downto 0) := (others => '0');
        variable i       : integer;
    begin
        bin_var := unsigned(bin);
        bcd_var := (others => '0');

        for i in 15 downto 0 loop
            -- Shift left
            bcd_var := bcd_var(14 downto 0) & bin_var(15);
            bin_var := bin_var(14 downto 0) & '0';

            -- Adiciona 3 se nibble >=5
            if bcd_var(3 downto 0) > 4 then
                bcd_var(3 downto 0) := bcd_var(3 downto 0) + 3;
            end if;
            if bcd_var(7 downto 4) > 4 then
                bcd_var(7 downto 4) := bcd_var(7 downto 4) + 3;
            end if;
            if bcd_var(11 downto 8) > 4 then
                bcd_var(11 downto 8) := bcd_var(11 downto 8) + 3;
            end if;
            if bcd_var(15 downto 12) > 4 then
                bcd_var(15 downto 12) := bcd_var(15 downto 12) + 3;
            end if;
        end loop;

        bcd <= std_logic_vector(bcd_var);
    end process;
end architecture rtl;
