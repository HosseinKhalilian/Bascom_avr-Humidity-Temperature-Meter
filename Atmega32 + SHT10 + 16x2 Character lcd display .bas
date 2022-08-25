'======================================================================='

' Title: LCD Display Thermometer * Humidity
' Last Updated :  01.2022
' Author : A.Hossein.Khalilian
' Program code  : BASCOM-AVR 2.0.8.5
' Hardware req. : Atmega32 + SHT10 + 16x2 Character lcd display

'======================================================================='

$regfile = "m32def.dat"
$crystal = 1000000

Config Lcdpin = Pin , Rs = Pina.0 , E = Pina.2 , Db4 = Pina.4 , Db5 = Pina.5 , Db6 = Pina.6 , Db7 = Pina.7
Config Lcd = 16 * 2
Cursor Off
Cls

Dim I As Byte
Dim Z As Single

Dim Data_byte As Byte
Dim Data_msb As Byte
Dim Data_lsb As Byte
Dim Data_word As Word
Dim Crc As Byte

Dim Temp As Single
Dim Rh_liner As Single
Dim Command As Byte

Sck Alias Portc.1
Dataout Alias Portc.0
Datain Alias Pinc.0

Config Portc.1 = Output
Config Portc.0 = Output

Gosub Signal_reset : Waitms 10

'-----------------------------------------------------------

Do
   Command = &B00000101 : Gosub Get_sht10
   Gosub Calcula_rh_liner_12bit

   Command = &B00000011 : Gosub Get_sht10
   Gosub Calcula_temp_14bit

   Gosub Display_lcd

   Wait 1
Loop

End

'-----------------------------------------------------------

Status_register_write:
   Gosub Signal_start
   Command = &B00000110 : Shiftout Dataout , Sck , Command , 1
   Gosub Signal_ack
   Command = &B00000000 : Shiftout Dataout , Sck , Command , 1
   Gosub Signal_ack
Return

''''''''''''''''''''''''''''''

Status_register_read:
   Gosub Signal_start
   Command = &B00000111
   Shiftout Dataout , Sck , Command , 1
   Gosub Signal_ack
   Gosub Read_byte : Data_msb = Data_byte
   Gosub Signal_ack
   Gosub Read_byte : Crc = Data_byte
   Print "Status Register=" ; Data_msb
   Print "Checksum=" ; Crc
   Print
Return

''''''''''''''''''''''''''''''

Setting_default:
   Gosub Signal_start
   Command = &B00011110 : Shiftout Dataout , Sck , Command , 1
   Gosub Signal_ack
   Waitms 100
Return

''''''''''''''''''''''''''''''

Get_sht10:
   Gosub Signal_start
   Gosub Send_command
   Gosub Signal_ack
   Gosub Wait_for_data_ready
   Gosub Read_byte : Data_msb = Data_byte
   Gosub Signal_ack
   Gosub Read_byte : Data_lsb = Data_byte
   Gosub Signal_ack
   Gosub Read_byte : Crc = Data_byte
   Gosub Signal_end
   Data_msb = Data_msb And &B00111111
   Data_word = Makeint(data_lsb , Data_msb)
Return

''''''''''''''''''''''''''''''

Signal_reset:
   Config Portc.1 = Output                                  ': Portc.1 = 1
   Config Portc.0 = Output                                  ': Portc.0 = 1
   Reset Sck : Set Dataout : Waitus 1
   For I = 1 To 9
      Set Sck : : Waitus 1 :
      Reset Dataout : Waitus 1
   Next I
Return

''''''''''''''''''''''''''''''

Signal_start:
   Config Portc.1 = Output                                  ': Portc.1 = 1
   Config Portc.0 = Output                                  ': Portc.0 = 1
   Reset Sck : Set Dataout : Waitus 1
   Set Sck : : Waitus 1 :
   Reset Dataout : Waitus 1
   Reset Sck : Waitus 1
   Set Sck : Waitus 1
   Set Dataout : : Waitus 1
   Reset Sck : Waitus 1
   Crc = 0
Return

''''''''''''''''''''''''''''''

Send_command:
   Config Portc.1 = Output : Portc.1 = 0
   Config Portc.0 = Output : Portc.0 = 0
   Shiftout Dataout , Sck , Command , 1
Return

''''''''''''''''''''''''''''''

Wait_for_data_ready:
   Config Portc.1 = Output                                  ': Portc.1 = 0
   Config Portc.0 = Input                                   ': Portc.0 = 0
   Set Dataout
   For I = 1 To 255
      If Dataout = 0 Then Exit For
      Waitms 1
   Next
Return

''''''''''''''''''''''''''''''

Read_byte:
   Config Portc.1 = Output : Portc.1 = 0
   Config Portc.0 = Input : Portc.0 = 1
   Shiftin Datain , Sck , Data_byte , 1
Return

''''''''''''''''''''''''''''''

Signal_ack:
   Config Portc.1 = Output                                  ': Portc.1 = 0
   Config Portc.0 = Output                                  ': Portc.0 = 0
   Reset Dataout : Reset Sck
   Set Sck : Waitus 1
   Reset Sck
Return

''''''''''''''''''''''''''''''

Signal_end:
   Config Portc.1 = Output                                  ': Portc.1 = 1
   Config Portc.0 = Output                                  ': Portc.0 = 1
   Set Dataout : Waitus 1
   Set Sck : Waitus 1
   Reset Sck : Waitus 1
Return

''''''''''''''''''''''''''''''

Calcula_rh_liner_12bit:
   Rh_liner = Data_word * Data_word
   Rh_liner = Rh_liner * -0.0000015955
   Z = 0.0367 * Data_word
   Rh_liner = Rh_liner + Z
   Rh_liner = Rh_liner - 2.0468
Return

''''''''''''''''''''''''''''''

Calcula_temp_14bit:
   Temp = 0.01 * Data_word
   Temp = Temp - 40.1
Return

''''''''''''''''''''''''''''''

Display_lcd:
   Deflcdchar 0 , 7 , 5 , 7 , 32 , 32 , 32 , 32 , 32
   Locate 1 , 1 : Lcd "RH: " ; Fusing(rh_liner , "#.#") ; "%  "
   Locate 2 , 1 : Lcd "Temp: " ; Fusing(temp , "#.#") ; Chr(0) ; "C  "
Return

'-----------------------------------------------------------