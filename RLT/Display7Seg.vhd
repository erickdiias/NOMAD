library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display7Seg is
    port(
        clk       : in  std_logic;                    -- clock rápido da FPGA
        bcd       : in  std_logic_vector(15 downto 0); -- 4 dígitos BCD
        seg       : out std_logic_vector(6 downto 0);  -- segmentos a-g
        an        : out std_logic_vector(3 downto 0)   -- enable dos displays
    );
end entity Display7Seg;

architecture rtl of Display7Seg is
    signal mux_cnt : unsigned(1 downto 0) := (others => '0'); -- contador para multiplexação
    signal bcd_digit : std_logic_vector(3 downto 0);
begin

    -- Multiplexação dos displays (~1 kHz)
    process(clk)
    begin
        if rising_edge(clk) then
            mux_cnt <= mux_cnt + 1;
        end if;
    end process;

    -- Seleciona qual dígito mostrar
    with mux_cnt select
        bcd_digit <= bcd(15 downto 12) when "00",  -- milhar
                     bcd(11 downto 8)  when "01",  -- centena
                     bcd(7 downto 4)   when "10",  -- dezena
                     bcd(3 downto 0)   when others; -- unidade

    -- Enable dos displays (ativo baixo)
    an <= "1110" when mux_cnt = "00" else
          "1101" when mux_cnt = "01" else
          "1011" when mux_cnt = "10" else
          "0111";

    -- Decodificador BCD para 7 segmentos
    with bcd_digit select
        seg <= "0000001" when "0000", -- 0
               "1001111" when "0001", -- 1
               "0010010" when "0010", -- 2
               "0000110" when "0011", -- 3
               "1001100" when "0100", -- 4
               "0100100" when "0101", -- 5
               "0100000" when "0110", -- 6
               "0001111" when "0111", -- 7
               "0000000" when "1000", -- 8
               "0000100" when "1001", -- 9
               "1111111" when others; -- off
end architecture rtl;
