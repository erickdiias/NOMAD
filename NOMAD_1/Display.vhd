library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display is
    port(
        clk : in std_logic;
        bcd_16bits_setpoint : in std_logic_vector(15 downto 0);
        bcd_16bits_mensurado : in std_logic_vector(15 downto 0);
        D0_a : out std_logic_vector(3 downto 0);
        D1_a : out std_logic_vector(3 downto 0);
        D0_seg : out std_logic_vector(6 downto 0);
        D1_seg : out std_logic_vector(6 downto 0)
    );
end entity;

architecture Behavioral of Display is
    signal selected_counter0 : std_logic_vector(3 downto 0);
    signal selected_counter1 : std_logic_vector(3 downto 0);
    signal counter4 : integer range 0 to 3 := 0;
    signal clk1ms : integer range 0 to 100000 := 0;
begin

    -- Contador para gerar clock de aproximadamente 1ms (100 MHz)
    process(clk)
    begin
        if rising_edge(clk) then
            if clk1ms = 99999 then
                clk1ms <= 0;
            else
                clk1ms <= clk1ms + 1;
            end if;
        end if;
    end process;

    -- Contador cíclico de 0 a 3 para multiplexação
    process(clk)
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

    -- Seleção dos dígitos para cada display
    process(clk)
    begin
        if rising_edge(clk) then
            case counter4 is
                when 0 =>
                    selected_counter0 <= bcd_16bits_setpoint(3 downto 0);
                    selected_counter1 <= bcd_16bits_mensurado(3 downto 0);
                    D0_a <= "1110";
                    D1_a <= "1110";
                when 1 =>
                    selected_counter0 <= bcd_16bits_setpoint(7 downto 4);
                    selected_counter1 <= bcd_16bits_mensurado(7 downto 4);
                    D0_a <= "1101";
                    D1_a <= "1101";
                when 2 =>
                    selected_counter0 <= bcd_16bits_setpoint(11 downto 8);
                    selected_counter1 <= bcd_16bits_mensurado(11 downto 8);
                    D0_a <= "1011";
                    D1_a <= "1011";
                when 3 =>
                    selected_counter0 <= bcd_16bits_setpoint(15 downto 12);
                    selected_counter1 <= bcd_16bits_mensurado(15 downto 12);
                    D0_a <= "0111";
                    D1_a <= "0111";
                when others =>
                    selected_counter0 <= (others => '0');
                    selected_counter1 <= (others => '0');
                    D0_a <= "0000";
                    D1_a <= "0000";
            end case;
        end if;
    end process;

    -- Decodificador BCD para display 7 segmentos (D0)
    process(clk)
    begin
        if rising_edge(clk) then
            case selected_counter0 is
                when "0000" => D0_seg <= "1000000";  -- 0
                when "0001" => D0_seg <= "1111001";  -- 1
                when "0010" => D0_seg <= "0100100";  -- 2
                when "0011" => D0_seg <= "0110000";  -- 3
                when "0100" => D0_seg <= "0011001";  -- 4
                when "0101" => D0_seg <= "0010010";  -- 5
                when "0110" => D0_seg <= "0000010";  -- 6
                when "0111" => D0_seg <= "1111000";  -- 7
                when "1000" => D0_seg <= "0000000";  -- 8
                when "1001" => D0_seg <= "0010000";  -- 9
                when others => D0_seg <= "1111111";  -- Display apagado
            end case;
        end if;
    end process;

    -- Decodificador BCD para display 7 segmentos (D1)
    process(clk)
    begin
        if rising_edge(clk) then
            case selected_counter1 is
                when "0000" => D1_seg <= "1000000";  -- 0
                when "0001" => D1_seg <= "1111001";  -- 1
                when "0010" => D1_seg <= "0100100";  -- 2
                when "0011" => D1_seg <= "0110000";  -- 3
                when "0100" => D1_seg <= "0011001";  -- 4
                when "0101" => D1_seg <= "0010010";  -- 5
                when "0110" => D1_seg <= "0000010";  -- 6
                when "0111" => D1_seg <= "1111000";  -- 7
                when "1000" => D1_seg <= "0000000";  -- 8
                when "1001" => D1_seg <= "0010000";  -- 9
                when others => D1_seg <= "1111111";  -- Display apagado
            end case;
        end if;
    end process;

end architecture;
