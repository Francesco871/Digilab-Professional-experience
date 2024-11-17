----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.05.2021 19:20:17
-- Design Name: 
-- Module Name: moving_average_filter - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity moving_average is
    Generic(
        LOG2_LEN: POSITIVE := 5;
        CHANNEL_LENGHT  : integer := 24
    );
    Port ( 
        s_axis_tready : OUT STD_LOGIC;
        s_axis_tdata : IN STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        s_axis_tlast : IN STD_LOGIC;
        s_axis_tvalid : IN STD_LOGIC;
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tdata : OUT STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        m_axis_tready : IN STD_LOGIC;
        m_axis_tlast : OUT STD_LOGIC;
        enable_filter_trig : IN STD_LOGIC;
        filter_enabled : OUT STD_LOGIC;
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC
    );
end moving_average;

architecture Behavioral of moving_average is
    constant LEN : integer := 2**LOG2_LEN;

    type state_type is (rx, buff, tx);
    type mem_type is array(integer range <>) of signed(CHANNEL_LENGHT-1 downto 0);
    type channel_type is (right, left);

    signal state: state_type :=rx;
    signal memL : mem_type(LEN-2 downto 0) :=(others=>(others=>'0'));
    signal memR : mem_type(LEN-2 downto 0) :=(others=>(others=>'0'));
    signal channel : channel_type;
    signal data : STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 downto 0);
    signal out_buff : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal enable_filter_reg : std_logic :='0';
    signal sumL : signed(CHANNEL_LENGHT+LOG2_LEN-1 downto 0) :=(others => '0');
    signal sumR : signed(CHANNEL_LENGHT+LOG2_LEN-1 downto 0) :=(others => '0'); 

    
begin
    with channel select m_axis_tlast<= '1' when right,
                                                '0' when others;
    
    with state select s_axis_tready<= '1' when rx,
                                               '0' when others;
    with state select m_axis_tvalid<= '1' when tx,
                                               '0' when others;
    filter_enabled<=enable_filter_reg;
    
    process(aclk, aresetn)
        
    begin
        if aresetn='0' then
            state<=rx;
            memL<=(others=>(others=>'0'));
            memR<=(others=>(others=>'0'));
            sumL<=(others => '0');
            sumR<=(others => '0'); 
            enable_filter_reg<='0'; 
        elsif rising_edge(aclk) then
            if enable_filter_trig='1' then
                enable_filter_reg<= not enable_filter_reg;
            end if;
            case state is
                when rx=>
                    if(s_axis_tvalid='1') then
                        data<=s_axis_tdata;
                        if s_axis_tlast='1' then
                            channel<=right;
                            sumR<=sumR+signed(s_axis_tdata)-memR(LEN-2);
                            memR(0)<=signed(s_axis_tdata);
                            for I in 1 to LEN-2 loop
                                memR(I)<=memR(I-1);
                            end loop;
                        else
                            channel<=left;
                            sumL<=sumL+signed(s_axis_tdata)-memL(LEN-2);
                            memL(0)<=signed(s_axis_tdata);
                            for I in 1 to LEN-2 loop
                                memL(I)<=memL(I-1);
                            end loop;
                        end if;
                        state<=buff;
                    end if;

                when buff =>
                    m_axis_tdata<=out_buff;
                    state <= tx; 

                when tx=>
                    if(m_axis_tready='1') then
                        state<=rx;
                    end if;
            end case;
        end if;
    end process;

    process(sumL,sumR, channel)
    
    begin
        if(enable_filter_reg='1') then
            if(channel=left) then
                out_buff<=std_logic_vector(sumL(CHANNEL_LENGHT+LOG2_LEN-1 downto LOg2_LEN));
            else
                out_buff<=std_logic_vector(sumR(CHANNEL_LENGHT+LOG2_LEN-1 downto LOg2_LEN));
            end if; 
        else
            out_buff<=data;
        end if;
    end process;


end Behavioral;
