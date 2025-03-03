library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Bin2bcd is
    port(
        bin_14bits_setpoint  : in  std_logic_vector(13 downto 0);
        bin_14bits_mensurado : in  std_logic_vector(13 downto 0);
        bcd_16bits_setpoint  : out std_logic_vector(15 downto 0);
        bcd_16bits_mensurado : out std_logic_vector(15 downto 0)
    );
end entity;

architecture main of Bin2bcd is

    -- Processo para converter binário para BCD
    function bin_to_bcd(bin_value : std_logic_vector(13 downto 0)) return std_logic_vector is
        variable bin_temp : unsigned(13 downto 0);
        variable bcd_temp : unsigned(15 downto 0) := (others => '0');
    begin
        bin_temp := unsigned(bin_value);

        for i in 0 to 13 loop
            -- Ajuste de dígitos BCD antes do deslocamento
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

            -- Deslocamento de 16 bits para a esquerda
            bcd_temp := (bcd_temp(14 downto 0) & bin_temp(13));
            bin_temp := (bin_temp(12 downto 0) & '0');
        end loop;

        return std_logic_vector(bcd_temp);
    end function;

begin

    process(bin_14bits_setpoint, bin_14bits_mensurado)
    begin
        -- Chama a função para converter os dois valores binários
        bcd_16bits_setpoint  <= bin_to_bcd(bin_14bits_setpoint);
        bcd_16bits_mensurado <= bin_to_bcd(bin_14bits_mensurado);
    end process;

end architecture;
