----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.07.2022 16:51:04
-- Design Name: 
-- Module Name: UART_Audio_Syncronyzer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_Audio_Syncronyzer is
    generic(
        CHANNEL_LENGHT  : integer := 24;
        CLCK_FREQ_MHZ     : integer := 100
    );
    Port (
        
        aclk			: in std_logic;
        aresetn			: in std_logic;

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tready	: out std_logic;

        m_axis_tvalid	: out std_logic;
        m_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        m_axis_tlast	: out std_logic;
        m_axis_tready	: in std_logic
    );
end UART_Audio_Syncronyzer;

architecture Behavioral of UART_Audio_Syncronyzer is
    constant count_max : integer := (CLCK_FREQ_MHZ*1000000)/(44100);

    signal count : integer range 0 to count_max-1 := 0;

    type state_type is ( WAITING, TX_LEFT, TX_RIGHT);

    signal state : state_type := WAITING;

    signal data_buff_right : std_logic_vector(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal data_buff_left  : std_logic_vector(CHANNEL_LENGHT-1 downto 0) := (others => '0');


begin

    with state select m_axis_tvalid <=
        '1' when TX_LEFT,
        '1' when TX_RIGHT,
        '0' when others;

    with state select m_axis_tlast <=
        '1' when TX_RIGHT,
        '0' when others;

    process (aclk, aresetn)
    begin
        if aresetn = '0' then
            count <= 0;
            state <= WAITING;
        elsif rising_edge(aclk) then
            case state is
                when WAITING =>
                    if count = count_max-1 then
                        count <= 0;
                        state <= TX_LEFT;
                        m_axis_tdata <= data_buff_left;
                    else
                        count <= count + 1;
                    end if;
                when TX_LEFT =>
                    if m_axis_tready = '1' then
                        state <= TX_RIGHT;
                        m_axis_tdata <= data_buff_right;
                    end if;
                    count <= count + 1;
                when TX_RIGHT =>
                    if m_axis_tready = '1' then
                        state <= WAITING;
                    end if;
                    count <= count + 1;
            end case;
        end if;
    end process;

    s_axis_tready <= '1';

    process (aclk, aresetn)

    begin

        if aresetn = '0' then
            data_buff_left <= (others => '0');
            data_buff_right <= (others => '0');
        elsif rising_edge(aclk) then
            if s_axis_tvalid = '1' then
                if s_axis_tlast = '1' then
                    data_buff_right <= s_axis_tdata;
                else
                    data_buff_left <= s_axis_tdata;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
