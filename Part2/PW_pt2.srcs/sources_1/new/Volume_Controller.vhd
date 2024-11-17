library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Volume_Controller is
    generic(
        CHANNEL_LENGHT  : integer := 24;
        JOYSTICK_LENGHT  : integer := 10;
        N : integer :=6
    );
    Port (
        
            aclk			: in std_logic;
            aresetn			: in std_logic;
            
            jstck_y         : in std_logic_vector(9 downto 0);
            jstck_valid     : in std_logic;
    
            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast    : in std_logic;
            s_axis_tready	: out std_logic;
    
            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic
        );
end Volume_Controller;

architecture Behavioral of Volume_Controller is
    constant vol_len : integer :=(2**JOYSTICK_LENGHT)/(2**N);
    constant LOWER_SAT : signed := to_signed(-2**(CHANNEL_LENGHT-1), CHANNEL_LENGHT);
    constant UPPER_SAT : signed := to_signed(2**(CHANNEL_LENGHT-1)-1, CHANNEL_LENGHT);

	type state_def	is (ACQUIRING, BUFF, SENDING);
	signal state : state_def :=ACQUIRING;
    signal volume : integer range 0 to vol_len :=0;
    signal data_buff : signed(CHANNEL_LENGHT-1 downto 0);
    signal out_buff : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal volume_up: std_logic :='0';

begin

	with state select s_axis_tready <=
		'1' when ACQUIRING,
		'0' when others;
	
	with state select m_axis_tvalid <=
		'1' when SENDING,
	    '0' when others;


	----- process per la macchina a stati----------
	process(aclk, aresetn)
	begin

		if aresetn = '0' then
			state <= ACQUIRING;
			volume<= 0;
            volume_up<='0';
		
		elsif rising_edge(aclk) then
			case state  is
			
				when ACQUIRING =>
					if s_axis_tvalid = '1' then
                        if(jstck_valid='1') then 
                            if(unsigned(jstck_y)>512) then
                                volume<=to_integer((unsigned(jstck_y)-512)/(2**N));
                                volume_up<='1';
                            else
                                volume<=to_integer((512-unsigned(jstck_y))/(2**N));
                                volume_up<='0';
                            end if;
                        end if;
						m_axis_tlast <= s_axis_tlast;
						state <= BUFF;
                        data_buff <= signed(s_axis_tdata);
					end if ;
                when BUFF =>
                    m_axis_tdata<=out_buff;
                    state <= SENDING;            
				when SENDING =>
					if m_axis_tready = '1' then
						state <= ACQUIRING;
					end if ;
			end case ;
        end if;

	end process;

    process(data_buff, volume)
        variable op : signed(vol_len + CHANNEL_LENGHT -1 downto 0);
        variable res : signed(vol_len + CHANNEL_LENGHT -1 downto 0);
    begin
        if volume=0 then 
            out_buff<=std_logic_vector(data_buff);
        else
            if volume_up='0' then
                out_buff<=std_logic_vector(shift_right(data_buff, volume));
            else 
                op:=resize(data_buff, op'length);
                res:=shift_left(op, volume);
                if(res<-2**(CHANNEL_LENGHT-1)) then
                    out_buff<=std_logic_vector(LOWER_SAT);
                elsif(res>2**(CHANNEL_LENGHT-1)-1) then
                    out_buff<=std_logic_vector(UPPER_SAT);
                else
                    out_buff<=std_logic_vector(res(CHANNEL_LENGHT-1 downto 0));
                end if;
            end if;
        end if;
    end process;
    -----------------------------------------------


end Behavioral;
