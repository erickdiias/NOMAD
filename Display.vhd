library ieee;
use ieee.std_logic_1164.all;
use ieee.Numeric_Std.all;

entity Display is
    Port(
        clk : in std_logic;
        bcd_16bits : in std_logic_vector(15 downto 0); -- bcd_16bits(15 downto 12) = milhar, bcd_16bits(11 downto 8) = centena, bcd_16bits(7 downto 4) = dezena, bcd_16bits(3 downto 0) = unidade
        D0_a : out std_logic_vector(3 downto 0);
        D0_seg : out std_logic_vector(6 downto 0)
    );
end entity;

architecture Behavioral of Display is

signal selected_counter : std_logic_vector(3 downto 0);
signal counter4 : integer range 0 to 3;
signal clk1ms : integer range 0 to 100000;
begin

    process(clk) -- Contador T=1ms
    begin
        if rising_edge(clk) then
            if clk1ms = 100000 then
                clk1ms <= 0;
            else
                clk1ms <= clk1ms + 1;
            end if;
        end if;
    end process;

    process(clk) -- Contador de 0 a 3 de T=4ms
    begin
        if rising_edge(clk) then
            if clk1ms = 0 then
                if counter4 = 3 then
                    counter4 <= 0;
                else
                    counter4 <= counter4 + 1;
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            case counter4 is
                when 0 =>
                    selected_counter <= bcd_16bits(3 downto 0);
                    D0_a <= "1110";
                when 1 =>
                    selected_counter <= bcd_16bits(7 downto 4);
                    D0_a <= "1101";
                when 2 =>
                    selected_counter <= bcd_16bits(11 downto 8);
                    D0_a <= "1011";
                when 3 =>
                    selected_counter <= bcd_16bits(15 downto 12);
                    D0_a <= "0111";
                when others =>
                    selected_counter <= (others => '0');
                    D0_a <= "0000";
            end case;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then 
            case selected_counter is
                when "0000" =>
                    D0_seg <= "1000000";  -- Mostrar 0
                when "0001" =>
                    D0_seg <= "1111001";  -- Mostrar 1
                when "0010" =>
                    D0_seg <= "0100100";  -- Mostrar 2
                when "0011" =>
                    D0_seg <= "0110000";  -- Mostrar 3
                when "0100" =>
                    D0_seg <= "0011001";  -- Mostrar 4
                when "0101" =>
                    D0_seg <= "0010010";  -- Mostrar 5 
                when "0110" =>
                    D0_seg <= "0000010";  -- Mostrar 6
                when "0111" =>
                    D0_seg <= "1111000";  -- Mostrar 7
                when "1000" =>
                    D0_seg <= "0000000";  -- Mostrar 8
                when "1001" =>
                    D0_seg <= "0010000";  -- Mostrar 9
                when others =>
                    D0_seg <= "1111111";  -- Apagar todos os segmentos
            end case;
        end if;
    end process;
    
end architecture;
