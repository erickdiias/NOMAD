-- =====================================================
-- Sistema UART Rx para comunicação FPGA-Arduino
-- Implementa receptor UART a 9600 baud
-- =====================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
        clk       : in  std_logic;               -- clock da FPGA
        rst       : in  std_logic;               -- reset assíncrono
        rx        : in  std_logic;               -- sinal de recepção serial
    );
end entity uart_rx;

architecture Behavioral of uart_rx is
begin
end architecture Behavioral;