//Readout Builder (lib_readout.ks)
//By space_is_hard

@LAZYGLOBAL OFF.

//Instructions:

//Call build_header at the start of your script and pass it a title and a list of three-
//letter-acronyms that represent each telemetry item you wish to be displayed at the top
//of the readout.

//Call update_header when you would like to update the telemetry at the top. Pass it a
//list of each value to print, in order of its corresponding TLA that you determined 
//using build_header

//Call readout_event when you want to print a specific message to the readout. Pass it
//the universal time (in seconds) that you consider T-0 and the message to print. Passing
//-1 as the T-0 time will print a message without the prefixed T-time.

//This script will set and modify a global variable called "readout_print_line", so be
//sure not to use that variable in any of your scripts.

FUNCTION build_header
{
    PARAMETER
        header_title,  //Title to put at the top of the header
        telemetry_TLA_list. //List of the telemetry parameter TLAs to print in the header
    
    CLEARSCREEN.
    SET TERMINAL:HEIGHT TO 40.
    SET TERMINAL:WIDTH TO 60.
    
    LOCAL middle_width TO ROUND(TERMINAL:WIDTH / 2).
    LOCAL half_header_title TO FLOOR(header_title:LENGTH / 2).
    IF MOD(header_title:LENGTH,2) <> 1
    {
        SET header_title TO header_title + "=".
    }.
    FROM { LOCAL i TO 0. } UNTIL i = TERMINAL:WIDTH STEP { SET i TO i + 1. } DO
    {
        IF i < (middle_width - half_header_title) OR i > FLOOR(middle_width + half_header_title)
        {
            PRINT "=" AT(i,0).
            
        }
        ELSE
        {
            PRINT header_title AT(i,0).
            SET i TO middle_width + half_header_title.
        
        }.
    }.
    LOCAL telemetry_lines TO CEILING(telemetry_TLA_list:LENGTH / 4).
    FROM{ LOCAL i TO 0. } UNTIL i = telemetry_lines STEP { SET i TO i + 1. } DO
    {
        FROM { LOCAL j TO 0. } UNTIL j = 4 STEP { SET j TO j + 1. } DO
        {
            PRINT telemetry_TLA_list[((i * 4) + (j + 1)) - 1] + ":" AT(j * FLOOR(TERMINAL:WIDTH / 4),i + 1).
        }.
        
    }.
    FROM { LOCAL i TO 0. } UNTIL i = TERMINAL:WIDTH STEP { SET i TO i + 1. } DO
    {
        PRINT "-" AT(i, telemetry_lines + 1).
    }.
    GLOBAL readout_print_line TO telemetry_lines + 2.
}.

FUNCTION update_header
{
    PARAMETER
        telemetry_list. //List of items to print; should correspond items from TLA list
    
    LOCAL telemetry_lines TO CEILING(telemetry_list:LENGTH / 4).
    FROM { LOCAL i TO 0. } UNTIL i = telemetry_lines STEP { SET i TO i + 1. } DO
    {
        FROM { LOCAL j TO 0. } UNTIL j = 4 STEP { SET j TO j + 1. } DO
        {
            LOCAL print_parameter TO telemetry_list[((i * 4) + (j + 1)) - 1] + "".
            IF print_parameter:LENGTH > 10
            {
                SET print_parameter TO print_parameter:REMOVE(10,print_parameter:LENGTH - 10).
            }
            ELSE IF print_parameter:LENGTH < 10
            {
                SET print_parameter TO print_parameter:PADRIGHT(10).
            }.
            PRINT print_parameter AT((j * FLOOR(TERMINAL:WIDTH / 4)) + 5,i + 1).
        }.
    }.
}.

FUNCTION readout_event
{
    PARAMETER
        t0_time,        //Time to consider as T-0
        string.        //Message to print; mind the length of the string
    
    IF TIME:SECONDS - t0_time < 0
    {
        PRINT "T" + ROUND(TIME:SECONDS - t0_time) + ": " + string AT(0,readout_print_line).
        
    }
    ELSE IF t0_time = -1
    {
        PRINT string AT(0,readout_print_line).
        
    }
    ELSE
    {
        PRINT "T+" + ROUND(TIME:SECONDS - t0_time) + ": " + string AT(0,readout_print_line).
        
    }.
    IF readout_print_line = TERMINAL:HEIGHT - 2
    {
        SET TERMINAL:HEIGHT TO MIN(60, TERMINAL:HEIGHT + 1).
    }.
    SET readout_print_line TO readout_print_line + 1.
}.
