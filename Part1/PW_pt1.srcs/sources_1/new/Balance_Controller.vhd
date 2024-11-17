library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Balance_Controller is
    generic(
        CHANNEL_LENGHT  : integer := 24;
        JOYSTICK_LENGHT  : integer := 10;
        N : integer :=6
    );
    Port (
        
            aclk			: in std_logic;
            aresetn			: in std_logic;
            
            jstck_x         : in std_logic_vector(JOYSTICK_LENGHT-1 downto 0);
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
end Balance_Controller;

architecture Behavioral of Balance_Controller is
    constant vol_len : integer :=(2**JOYSTICK_LENGHT)/(2**N);
    constant LOWER_SAT : signed := to_signed(-2**(CHANNEL_LENGHT-1), CHANNEL_LENGHT);
    constant UPPER_SAT : signed := to_signed(2**(CHANNEL_LENGHT-1)-1, CHANNEL_LENGHT);

	type state_def	is (ACQUIRING, BUFF, SENDING);
    type channel_type is (left, right);
	signal state : state_def :=ACQUIRING;
    signal volume : integer range 0 to vol_len;
    signal data_buff : signed(CHANNEL_LENGHT-1 downto 0);
    signal volume_ch: channel_type :=right;
    signal channel : channel_type;

begin

    with channel select m_axis_tlast<=
        '1' when right,
        '0' when others;

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
            volume_ch<=right;
		
		elsif rising_edge(aclk) then
			case state  is
			
				when ACQUIRING =>
					if s_axis_tvalid = '1' then
                        if(jstck_valid='1') then 
                            if(unsigned(jstck_x)>512) then
                                volume<=to_integer((unsigned(jstck_x)-512)/(2**N));
                                volume_ch<=left;
                            else
                                volume<=to_integer((512-unsigned(jstck_x))/(2**N));
                                volume_ch<=right;
                            end if;
                        end if;
                        if s_axis_tlast='1' then
                            channel<=right;
                        else
                            channel<=left;
                        end if;
						state <= BUFF;
                        data_buff <= signed(s_axis_tdata);
					end if ;

                when BUFF =>
                    if volume=0 then 
                        m_axis_tdata<=std_logic_vector(data_buff);
                    else
                        if volume_ch=right then
                            if(channel=right) then
                                m_axis_tdata<=std_logic_vector(shift_right(data_buff, volume));
                            else
                                m_axis_tdata<=std_logic_vector(data_buff);
                            end if;
                        else
                            if(channel=left) then
                                m_axis_tdata<=std_logic_vector(shift_right(data_buff, volume));
                            else
                                m_axis_tdata<=std_logic_vector(data_buff);
                            end if;
                        end if;
                    end if;
                    state <= SENDING; 
                 
				when SENDING =>
					if m_axis_tready = '1' then
						state <= ACQUIRING;
					end if ;
			end case ;
        end if;

	end process;

    process(data_buff, volume)
    begin
        
        
    end process;
    -----------------------------------------------


end Behavioral;
