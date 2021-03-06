{$A+,B-,D+,E+,F-,G+,I-,L+,N-,O-,P-,Q-,R-,S-,T-,V+,X+,Y+}
{$M 64000,0,0}  {BP 7.0 compiler options}

{ FREEWARE 1995 by BUGSY & SPAWN of OBSESSiON                                }
{ This is the Manzon nuker source-code.                                      }
{ Do with it as you like, just remember who made it.                         }
{                                                                            }
{ Contact us if you like. Coders are :                                       }
{                                                                            }
{ Benjamin Petersen                                                          }
{ Joergen Jensensvej 16B                                                     }
{ 4700 Naestved, Denmark                                                     }
{ Phone # : +45 53725610 or +45 40204347                                     }
{ Internet mail address : bugsy@cybernet.dk                                  }
{                                                                            }
{ Michael Skovslund                                                          }
{ Stationsvej 2                                                              }
{ 4681 Herfoelge, Denmark                                                    }
{ Phone # : +45 56275314                                                     }
{                                                                            }
{            Well, sorry about missing comments in the source code!          }
{                                                                            }
{                          BUGSY & SPAWN of ...			             }
{                   ▄─▄ ▄   ▄─▄ ▄─▄ ▄─▄ ▄─▄ ▄ ▄─▄ ▄─▄			     }
{                   █ █ █─▄ ▀─▄ █─  ▀─▄ ▀─▄ ▄ █ █ █ █   		     }
{                   █ █ █ █ ▄ █ █   ▄ █ ▄ █ █ █ █ █ █  			     }
{                   ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀ ▀▀▀ ▀ ▀  			     }
Program NukeManzon;

Uses
  Crt,
  Dos;

Const
  UnExpInt21h  = 0;
  InsFound     = 1;
  LoadError    = 2;
  EnvError     = 3;
  FreeError    = 4;
  BrokenFile   = 5;
  UnknownVer   = 6;
  MyFileSize   = 21968 + 2;                 {Remember to change this one}
  MyFileName   = 'NUKEMANZ.EXE';
  NameOfVirus  = 'MANZON';
  MinVirusSize = 1000;                   {Remember to change this one}
  InsTabel     : Array [0..19] Of Byte = (0,$E8,$8B,$8B,$81,$B9,$E8,$2E,$46,$E2,$C3,$58,$C3,$E8,$5E,$56,$1E,$0E,$1F,$B8);

Type
  ExeHeaderType    = Record
    ExeSign        ,
    ByteOnLastPage ,
    FileSizeDIV512 ,
    NumberOfRel    ,
    HeaderSizeInP  ,
    MinMemInP      ,
    MaxMemInP      ,
    _SS            ,
    _SP            ,
    ChkSum         ,
    _IP            ,
    _CS            ,
    RelocTabel     ,
    Overlay        : Word;
  End;

  LoadAndExecType = Record
    Environment ,
    OfsParam    ,
    SegParam    : Word;
    FCB         : Array [1..4] Of Word;
    _SP         ,
    _SS         ,
    _IP         ,
    _CS         : Word;
  End;

Var
  RetFFound   ,
  In1Decrypt  ,
  CxWasZero   ,
  CXWasZero2  : Byte;

  OldSS       ,
  OldSP       ,

  InsCount    ,
  InsTabelCt  ,

  VirVersion  ,
  FileError   ,
  ChildePSP   ,
  H           ,
  M           ,
  S           ,
  Hund        ,
  SubCt       : Word;

  NumOfFile   ,
  NumOfVirF   ,
  NumOfVirR   ,
  EntryPtr    : LongInt;

  OldDir      ,
  FileNameStr ,
  MyPathStr   ,
  MyDir       ,
  TempPath    ,
  ExecName    ,
  Parameter   ,
  Buffer      : String;

  Always      ,
  ComFile     ,
  ESC         ,
  DoSub       ,
  Beep        ,
  NoClean     ,
  Debug       ,
  Prompt      : Boolean;

  Path        : PathStr;
  Dir         : DirStr;
  Name        : NameStr;
  Ext         : ExtStr;

  InFile      : File of Byte;
  HdrInFile   : File Of ExeHeaderType;

  DirInfo     : SearchRec;
  ExeHeader   : ExeHeaderType;
  LoadAndExec : LoadAndExecType;
  OrgComCode  : Array [1..3] Of Byte;

Function ErrorText : String;
Begin
  Case FileError Of
    1   : ErrorText := 'Invalid function number.';
    2   : ErrorText := 'File not found.';
    3   : ErrorText := 'Path not found.';
    4   : ErrorText := 'Too many open files.';
    5   : ErrorText := 'File access denied.';
    6   : ErrorText := 'Invalid file handle.';
    12  : ErrorText := 'Invalid file access code.';
    15  : ErrorText := 'Invalid drive number.';
    16  : ErrorText := 'Cannot remove current directory.';
    17  : ErrorText := 'Cannot rename across drives.';
    18  : ErrorText := 'No more files.';
    100 : ErrorText := 'Disk read error.';
    101 : ErrorText := 'Disk write error.';
    102 : ErrorText := 'File not assigned.';
    103 : ErrorText := 'File not open.';
    104 : ErrorText := 'File not open for input.';
    105 : ErrorText := 'File not open for output.';
    106 : ErrorText := 'Invalid numeric format.';
    150 : ErrorText := 'Disk is write-protected.';
    151 : ErrorText := 'Bad drive request struct length.';
    152 : ErrorText := 'Drive not ready.';
    154 : ErrorText := 'CRC error in data.';
    156 : ErrorText := 'Disk seek error.';
    157 : ErrorText := 'Unknown media type.';
    158 : ErrorText := 'Sector Not Found.';
    159 : ErrorText := 'Printer out of paper.';
    160 : ErrorText := 'Device write fault.';
    161 : ErrorText := 'Device read fault.';
    162 : ErrorText := 'Hardware failure.';
    200 : ErrorText := 'Division by zero.';
    201 : ErrorText := 'Range check error.';
    202 : ErrorText := 'Stack overflow error.';
    203 : ErrorText := 'Heap overflow error.';
    204 : ErrorText := 'Invalid pointer operation.';
    205 : ErrorText := 'Floating point overflow.';
    206 : ErrorText := 'Floating point underflow.';
    207 : ErrorText := 'Invalid floating point operation.';
    208 : ErrorText := 'Overlay manager not installed.';
    209 : ErrorText := 'Overlay file read error.';
    210 : ErrorText := 'Object not initialized.';
    211 : ErrorText := 'Call to abstract method.';
    212 : ErrorText := 'Stream registration error.';
    213 : ErrorText := 'Collection index out of range.';
    214 : ErrorText := 'Collection overflow error.';
    215 : ErrorText := 'Arithmetic overflow error.';
    216 : ErrorText := 'General Protection fault.'
  Else
    ErrorText := 'Not found.';
  End;
End;

Procedure Error (Err : Byte);
Begin
  Write ('Error (',Err,') : ');
  Case Err Of
    1 : WriteLn ('No files found.');
    2 : WriteLn ('Can''t find directory.');
    3 : Begin
          WriteLn (NameOfVirus,' virus is resident in memory !');
          WriteLn ('            Boot from a clean floppy and try again.');
          WriteLn ('            Please reinstall this killer, because it can be infected.');
        End;
    4 : WriteLn (MyFileName, ' has been changed !. Virus ?');
    6 : WriteLn ('Can''t seek into file.');
    7 : WriteLn ('Can''t read from file.');
    8 : WriteLn ('Can''t close file.');
    9 : WriteLn ('Can''t open file.');
   10 : WriteLn ('Can''t write to file.');
   11 : WriteLn ('Can''t truncate file.');
   12 : WriteLn ('Can''t get directory.');
   14 : WriteLn ('Remember to add a 2 byte (HA) overlay.');{ Internal        }
                                                           { Use any hex file}
                                                           { editor to add a }
                                                           { 2 byte overlay  }
                                                           { in the exefile  }
                                                           { The overlay MUST}
                                                           { be 'HA'         }
                                                           { This is done to }
                                                           { prevent replicat}
                                                           { to infect this  }
                                                           { nuker           }
  Else
    WriteLn ('Not defined, programmer forgot this one !');   {hmmmmm....}
  End;
  If OldDir <> '' Then ChDir(OldDir);
  If IOResult <> 0 Then;
  Window (1, 1, 80, 25);
  GotoXY (1, 24);
  Halt (1);
End;

Procedure WriteHelpScr;
Var
  OldX, OldY : Byte;

Begin
  GotoXY (WhereX, WhereY-1);
  WriteLn ('┌────────────────────────────────────────────────────────┬────────────────────┐');
  WriteLn ('│USAGE : Nukemanz [path]filename.ext [/nc] [/b] [/s] [/p]│    E-MAIL us at    │');
  WriteLn ('│                                                        │ bugsy@cybernet.dk  │');
  WriteLn ('│You can use ANY valid dos wildcard.                     │                    │');
  WriteLn ('│                                                        ├────────────────────┤');
  WriteLn ('│/NC no clean  /P prompt before cleaning file            │  The groupe named  │');
  WriteLn ('│/B  beep      /S search subdirectory                    │   IR made MANZON   │');
  WriteLn ('├─────────────────────────────────────────────────┬──────┴────────────────────┤');
  WriteLn ('│ │        Coded by BUGSY & SPAWN of..            │ This is a killer for the  │');
  WriteLn ('│─∙──--                                           │ two variants of the virus │');
  WriteLn ('│ │ ▄─▄ ▄   ▄─▄ ▄─▄ ▄─▄ ▄─▄ ▄ ▄─▄ ▄─▄             │ MANZON.1404 & MANZON.1416 │');
  WriteLn ('│ | █ █ █─▄ ▀─▄ █─  ▀─▄ ▀─▄ ▄ █ █ █ █             │ ------------------------- │');
  WriteLn ('│   █ █ █ █ ▄ █ █   ▄ █ ▄ █ █ █ █ █ █             │ HEY TU, why don''t you tell│');
  WriteLn ('│   ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀ ▀▀▀ ▀ ▀ ▀           │ xxx-x/xx that he should do│');
  WriteLn ('│ If you want to contact us, our addresses are  : │ his coding job insted of  │');
  WriteLn ('├────────────────────────┬────────────────────────┤ making those LAME viruses │');
  WriteLn ('│ Benjamin Petersen      │ Michael Skovslund      │ ------------------------- │');
  WriteLn ('│ Joergen Jensensvej 16B │ Stationsvej 2          │ Feel free to contact me,  │');
  WriteLn ('│ 4700 Naestved, Denmark │ 4681 Herfoelge, Denmark│ if you wanna get the src! │');
  WriteLn ('│ Phone # : +45 53725610 │ Phone # : +45 56275314 │     Yours BUGSY/OBSESSiON │');
  WriteLn ('└────────────────────────┴────────────────────────┴───────────────────────────┘');
  OldX := WhereX;
  OldY := WhereY;
  GotoXY (OldX, OldY);
  Halt (1);
End;

Function VirusIsInMem : Boolean; Assembler;
Asm
  mov  ax, 0DCBAh			{Virus id word}
  int  21h
  cmp  dx, ax
  mov  ax, 0
  jne  @NOVirus
  mov  ax, 1
@NOVirus:
End;

Function TestForVir : Boolean;
Var
  TempByte : Byte;
  TempWord : Word;

Begin
  TestForVir := False;
  Read (InFile, TempByte);
  If IOResult <> 0 Then Error (7);
  If TempByte = $B9 Then Begin              {mov cx, ???? opcode}
    Read (InFile, TempByte);
    If IOResult <> 0 Then Error (7);
    Read (InFile, TempByte);
    If IOResult <> 0 Then Error (7);
    Read (InFile, TempByte);
    If IOResult <> 0 Then Error (7);
    If TempByte = $BE Then Begin                 {mov si, ???? opcode}
      TestForVir := True;
      GotoXY (WhereX-1, WhereY);
      Write (', infected with ',NameOfVirus);
      TestForVir := True;
    End;
  End;
End;

Procedure DelFile (InName : String);
Var
  Ch   : Char;
  DelF : File;

Begin
  Write ('Delete the file (Y/N/A) ? ');
  If NOT Always Then Ch := Upcase (ReadKey) Else Ch := 'Y';
  If Ch = 'A' Then ALWAYS := True;
  If (Ch = 'Y') OR ALWAYS Then Begin
    WriteLn ('Y');
    Assign (DelF, InName);
    Erase (DelF);
    If IOResult <> 0 Then;
  End Else
    WriteLn ('N');
End;

Function ChkFile : Boolean;
Var
  Ct        ,
  TempByte  : Byte;
  TempWord  : Word;

Begin
  FileMode := 0;   {ReadOnly mode}
  ChkFile := False;

  If DirInfo.Name[Length(DirInfo.Name)] = '.' Then Exit;
  If DirInfo.Attr AND Directory = Directory Then Exit;
  If DirInfo.Attr AND VolumeID = VolumeID Then Exit;
  Inc (NumOfFile);
  If MyDir[Length(MyDir)] = '\' Then
    Write (MyDir,DirInfo.Name,' ')
  Else
    Write (MyDir,'\',DirInfo.Name,' ');

  If DirInfo.Size < MinVirusSize Then Begin
    ChkFile := False;
    WriteLn;
    Exit;
  End;

  Assign (InFile, DirInfo.Name);

  Reset (InFile);
  If IOResult <> 0 Then Begin
    WriteLn (' ERROR : Can''t open file, share violation ?');
    ChkFile := False;
    Exit;
  End;

  {Test if EXE-file}
  ComFile := False;
  Read (InFile, TempByte);
  If IOResult <> 0 Then Error (7);
  If (TempByte = Byte('M')) OR (TempByte = Byte('Z')) then Begin
    Read (InFile, TempByte);
    If IOResult <> 0 Then Error (7);
    If (TempByte = Byte('M')) OR (TempByte = Byte('Z')) then Begin
      {Get EXE-header}
      Assign (HdrInFile, DirInfo.Name);
      Reset (HdrInFile);
      If IOResult <> 0 Then Error (9);
      Read (HdrInFile, ExeHeader);
      If IOResult <> 0 Then Error (7);
      Close (HdrInFile);
      If IOResult <> 0 Then Error (8);
      {Seek To Code}
      TempWord := ExeHeader._CS + (ExeHeader._IP SHR 4);
      EntryPtr := LongInt (TempWord) * $10 + (ExeHeader._IP AND $000F) + (ExeHeader.HeaderSizeInP * $10);
      If DirInfo.Size < (EntryPtr + 3) Then Begin
        WriteLn ('Entry point to code is out of size!.');
        WriteLn ('File does NOT work! (The virus fucked it up!)');
        DelFile (DirInfo.Name);
      End Else Begin
        Reset (InFile);
        Seek (InFile, EntryPtr);
        If IOResult <> 0 Then Error (6);
        ChkFile := TestForVir;
      End;
    End;
  End Else Begin
    {Assume COM-file}
    ComFile := True;
    Reset (InFile);
    Read (InFile, TempByte);
    If IOResult <> 0 Then Error (7);
    If TempByte = $E9 then Begin                  {Jump opcode}
      Read (InFile, TempByte);                    {read jump location}
      If IOResult <> 0 Then Error (7);
      TempWord := TempByte;
      Read (InFile, TempByte);
      If IOResult <> 0 Then Error (7);
      TempWord := TempWord + (TempByte*256) + 3;  {+3 for opcode size}
      EntryPtr := TempWord;
      If Dirinfo.Size <= (EntryPtr  + 3) Then Begin
        WriteLn ('Entry point to code is out of size!.');
        WriteLn ('File does NOT work! (The virus fucked it up!)');
        DelFile (DirInfo.Name);
      End Else
      Begin
        Reset (InFile);
        Seek (InFile, TempWord);
        If IOResult <> 0 Then Error (6);
          ChkFile := TestForVir;
      End;
    End;
  End;
  Close (InFile);
  WriteLn;
  FileMode := 2;       {Read/Write mode}
End;

Procedure NewInt01; ASSEMBLER;
Asm
  pusha
  push    es
  push    ds

  mov     ax, Seg OldSS                 {Setup our datasegment}
  mov     ds, ax

  mov     bp, sp
  mov     al, 3
  or      ss:[bp+14h+5], al  {set trap and interruptflag on return}

  les     di, ss:[bp+14h]

@TestVirusIns:
  cmp     CXWasZero2, 1
  je      @TheCXWasZero2

  cmp     CXWasZero, 1
  je      @TheCXWasZero

  cmp     RetFFound, 1
  je      @TheRetFFound

  cmp     byte ptr es:[di], 0cbh        {retf opcode}
  jne     @NextIns
  mov     RetFFound, 1
  jmp     @NextIns

@TheRetFFound:
  cmp     InsCount, 5
  je      @TestForCXZero
  inc     InsCount
  jmp     @NextIns

@TestForCXZero:
  cmp     cx, 0
  jne     @NextIns

  mov     CXWasZero, 1
  mov     InsCount, 0
  jmp     @NextIns

@TheCXWasZero:
  inc     InsCount
  cmp     InsCount, 7
  jb      @CXNOTZero

  cmp     cx, 0
  je      @SetCXWasZero2
  cmp     InsCount, 10
  jne     @CXNOTZero
  mov     InsCount, 7
  jmp     @CXNOTZero

@TheCXWasZero2:
  inc     InsCount

@SetCXWasZero2:
  mov     CXWasZero2, 1

@CXNOTZero:
  mov     bx, InsCount
  mov     si, offset InsTabel
  mov     al, es:[di]             {Virus opcode}

  xchg    bx, dx
  cmp     dx, 19
  mov     bl, InsFound
  je      @GetOut
  xchg    dx, bx

  cmp     al, [si+bx]             {test for same in tabel}
  mov     bl, BrokenFile
  je      @NextIns

@GetOut:
  mov     ax, Seg OldSS
  mov     ds, ax
  cli
  mov     ss, OldSS
  mov     sp, OldSP
  sti

  cmp     byte ptr es:[di+8h], 61h
  jne     @ChkVersion2

  mov     VirVersion,  1416

  cmp     word ptr es:[di-2a4h], 0100h
  je      @Version1Com

@Version1Exe:
  mov     ax, es:[di-2ach]
  mov     Exeheader._CS, ax
  mov     ax, es:[di-2aah]
  mov     Exeheader._IP, ax
  mov     ax, es:[di-2a8h]
  mov     Exeheader._SS, ax
  mov     ax, es:[di-2a6h]
  mov     Exeheader._SP, ax
  sub     word ptr ExeHeader.MinMemInP, 0071h
  retf

@Version1Com:
  mov     al, byte ptr es:[di-2B2h]
  mov     byte ptr OrgComCode[0], al

  mov     al, byte ptr es:[di-2B2h+1]
  mov     byte ptr OrgComCode[1], al

  mov     al, byte ptr es:[di-2B2h+2]
  mov     byte ptr OrgComCode[2], al
  retf

@ChkVersion2:
  cmp     byte ptr es:[di+8h], 5Ch
  jne     @UnknownVersion

  mov     VirVersion, 1404
  cmp     word ptr es:[di-2a1h], 0100h
  je      @Version2Com

@Version2Exe:
  mov     ax, es:[di-2a9h]
  mov     Exeheader._CS, ax
  mov     ax, es:[di-2a7h]
  mov     Exeheader._IP, ax
  mov     ax, es:[di-2a5h]
  mov     Exeheader._SS, ax
  mov     ax, es:[di-2a3h]
  mov     Exeheader._SP, ax
  sub     word ptr ExeHeader.MinMemInP, 0070h
  retf

@Version2Com:
  mov     al, byte ptr es:[di-2afh]
  mov     byte ptr OrgComCode[0], al

  mov     al, byte ptr es:[di-2afh+1]
  mov     byte ptr OrgComCode[1], al

  mov     al, byte ptr es:[di-2afh+2]
  mov     byte ptr OrgComCode[2], al
  retf

@UnknownVersion:
  mov     bl, UnknownVer
  retf

@NextIns:
  pop     ds
  pop     es
  popa
  iret
End;

Function TraceFile : Byte;
label TrapReturn;
Var
  Ct       : Byte;
  OldInt01 : Procedure;

Begin
  RetFFound  := 0;
  CxWasZero  := 0;
  CxWasZero2 := 0;
  InsCount   := 0;

  GetIntVec ($01, @OldInt01);
  SetIntVec ($01, @NewInt01);
  ExecName := DirInfo.Name + ' ';

  ExecName[Length (ExecName)] := #0;
  Parameter[0] := #$00;
  Parameter[1] := #$0D;

  With LoadAndExec Do Begin
    Environment := $0000;
    OfsParam := ofs (Parameter);
    SegParam := seg (Parameter);
    For Ct := 1 To 4 Do FCB[Ct] := $FFFF;
  End;
  SwapVectors;
  FileError := 0;
  asm
    push     bp
    mov      dx, offset ExecName + 1
    push     ds
    pop      es
    mov      bx, offset LoadAndExec
    mov      ax, 4B01h
    int      21h

    mov      FileError, ax
    mov      @result, LoadError
    jc       @Error

@NoError:
    mov      ah, 62h
    int      21h
    mov      ChildePSP, bx

    push     cs
    push     offset TrapReturn

    mov      OldSS, ss
    mov      OldSP, sp

    mov      al, 1
    pushf
    mov      bp, sp
    or       ss:[bp+1], al
    popf

    cli
    mov      ss, LoadAndExec._SS
    mov      sp, LoadAndExec._SP
    sti
    mov      es, ChildePSP

    push     LoadAndExec._CS
    push     LoadAndExec._IP

    mov      ds, LoadAndExec._CS

    cld
    xor      ax, ax
    mov      bx, ax
    mov      cx, ax
    mov      dx, ax
    mov      si, ax
    mov      di, ax
    mov      bp, ax

    retf
    {set trap flag and retf}

TrapReturn:
    pop      bp
    mov      @result, bl

    mov      ah, 50h
    mov      bx, PrefixSeg
    int      21h

    mov      ax, ChildePSP
    mov      es, ax

    push     es
    mov      es, es:[2ch]
    mov      ah, 49h
    int      21h
    jnc      @NoEnvError
    mov      @result, EnvError
    jmp      @GetOut

@NoEnvError:
    pop      es
    mov      ah, 49h
    int      21h
    jnc      @GetOut
    mov      @result, FreeError

@Error:
    pop      bp

@GetOut:
  end;
  SwapVectors;
  SetIntVec ($01, @OldInt01);
End;

Procedure CleanComFile;
Var
  Ct : Byte;

Begin
  Assign (InFile, DirInfo.Name);
  Reset (InFile);
  For Ct := 1 To 3 Do
    Write (InFile, OrgComCode[Ct]);
  If IOResult <> 0 Then Error (9);
  Seek (InFile, EntryPtr);
  If IOResult <> 0 Then Error (6);
  Truncate (InFile);
  If IOResult <> 0 Then Error (11);
  Close (InFile);
  If IOResult <> 0 Then Error (8);
End;

Procedure CleanExeFile;
Begin
  ExeHeader.FileSizeDIV512 := EntryPtr DIV $200;
  ExeHeader.ByteOnLastPage := EntryPtr MOD $200;
  If ExeHeader.ByteOnLastPage <> 0 Then Inc (ExeHeader.FileSizeDIV512);
  Assign (HdrInFile, DirInfo.Name);
  Reset (HdrInFile);
  If IOResult <> 0 Then Error (9);
  Write (HdrInFile, ExeHeader);
  If IOResult <> 0 Then Error (10);
  Close (HdrInFile);
  If IOResult <> 0 Then Error (8);

  Assign (InFile, DirInfo.Name);
  Reset (InFile);
  If IOResult <> 0 Then Error (9);
  Seek (InFile, EntryPtr);
  If IOResult <> 0 Then Error (6);
  Truncate (InFile);
  If IOResult <> 0 Then Error (11);
  Close (InFile);
  If IOResult <> 0 Then Error (8);
End;


Procedure CleanFile;
Var
  Ct       : Byte;
  SndCt    : Word;
  Ch       : Char;

Begin
  Inc (NumOfVirF);
  If Beep Then
    For Ct := 1 To 2 Do Begin
      For SndCt := 0 To 100 Do Begin
        Sound(1000+(8*SndCt));
        Delay(1);
      End;
      For SndCt := 100 DownTo 0 Do Begin
        Sound(1000+(8*SndCt));
        Delay(1);
      End;
      NoSound;
      NoSound;    {Just in case, I really hate that beeper}
    End;

  If NoClean Then Exit;

  If Prompt Then Begin
    Write('Do you wish to clean this file (Y/N/A) ? ');
    If NOT Always Then Ch := Upcase (ReadKey) Else Ch := 'Y';
    If Ch = 'A' Then ALWAYS := True;
    If (Ch = 'Y') OR Always Then
      WriteLn (Ch)
    Else Begin
      WriteLn ('N');
      Exit;
    End;
  End;

  Write ('Tracking virus : ');
  Case TraceFile of
    UnExpInt21h  : Begin
                     WriteLn ('Unexpeted interrupt occured, file ^properly^ not infected!');
                     WriteLn ('Press almost any key');
                     ReadKey;
                   End;
    InsFound     : Begin
                     WriteLn ('ok, virus decrypted. Version ', VirVersion );
                   End;
    LoadError    : Begin
                     WriteLn ('Can''t load file : ', ErrorText);
                     DelFile (Dirinfo.Name);
                     Exit;
                   End;
    EnvError     : Begin
                     WriteLn ('Can''t free enviroment');
                     WriteLn ('Press almost any key');
                     ReadKey;
                   End;
    FreeError    : Begin
                     WriteLn ('Can''t free file');
                     WriteLn ('Press almost any key');
                     ReadKey;
                   End;
    BrokenFile   : Begin
                     WriteLn ('File might be infected, but does NOT work!');
                     DelFile (DirInfo.Name);
                     Exit;
                   End;
    UnknownVer   : Begin
                     WriteLn ('This is a unknown version of the MANZON virus');
                     DelFile (DirInfo.Name);
                     Exit;
                   End;
  Else
    WriteLn ('Unknown Error! (BUGSY you''r a jerk!)');
  End;

  Write ('Cleaning file, ');
  If DirInfo.Attr AND ReadOnly = ReadOnly Then Begin
    WriteLn ('BAD. ------> read only <------');
    WriteLn ('Press almost any key.');
    ReadKey;
    Exit;
  End;

  If ComFile Then CleanComFile
  Else CleanExeFile;

  WriteLn ('Done.');
  Inc (NumOfVirR);
End;

Procedure OneDir;
Var
  Ch : Char;

Begin
  GetDir(0, MyDir);
  If IOResult <> 0 Then Error (12);
  FindFirst (FileNameStr, Anyfile, DirInfo);
  While (DosError = 0) AND (ESC = False) Do Begin
    If Keypressed Then Begin
      Ch := ReadKey;
      If Ch = #27 Then
        ESC := True;
    End;
    If ChkFile Then CleanFile;
    FindNext(DirInfo);
  End;
End;

Procedure DoSubDir (SubDirInfo : SearchRec);
Begin
  If ESC Then Exit;
  If SubCt <> 0 Then Begin
    ChDir (SubDirInfo.Name);
    If IOResult <> 0 Then Error (2);
  End;
  Inc (SubCt);

  If DosError = 0 Then Begin
    FindFirst ('*.*', AnyFile, SubDirInfo);
    If (SubDirInfo.Attr AND Directory = Directory) And (SubDirInfo.Name[1] <> '.') Then
      DoSubDir (SubDirInfo);
    While DosError = 0 Do Begin
      FindNext (SubDirInfo);
      If DosError <> 0 Then Break;
      If (SubDirInfo.Attr AND Directory = Directory) And (SubDirInfo.Name[1] <> '.')Then
        DoSubDir (SubDirInfo);
    End;
    Dec (SubCt);

    GetDir (0, TempPath);
    If IOResult <> 0 Then Error (2);
    OneDir;
    DosError := 0;
    If SubCt <> 0 Then Begin
      ChDir ('..');
      If IOResult <> 0 Then Error (2);
    End;
  End;
End;

Procedure FindVirus;
Var
  TempStr   : String[2];
  TempByte  : Byte;
  TimeUsed  : LongInt;

Begin
  Always := False;
  GetTime (H,M,S,Hund);
  TimeUsed := ((H * 3600) + (M * 60) + S);
  Window (1, 7, 80, 22);

  If NOT Debug Then Begin
    If VirusIsInMem Then Error (3);
{    FindFirst (ParamStr(0), AnyFile, DirInfo);
    If (DirInfo.Size <> MyFileSize) OR (DirInfo.Name <> MyFileName) Then Error (4);

    TempStr := '--';
    Assign (InFile, ParamStr(0));
    Reset (InFile);
    Seek (InFile, DirInfo.Size-2);
    Read (InFile, Byte(TempStr[1]));
    Read (InFile, Byte(TempStr[2]));
    Close (InFile);
    If TempStr <> 'HA' Then Error (14);}
  End;

  GetDir (0, OldDir);
  If MyPathStr <> '' Then Begin
    ChDir(MyPathStr);
    If IOResult <> 0 Then Error (2);
  End;

  If DoSub Then Begin
    SubCt := 0;
    DirInfo.Name := FileNameStr;
    DosError := 0;
    DoSubDir (DirInfo)
  End Else
    OneDir;

  If MyPathStr <> '' Then Begin
    ChDir (OldDir);
    If IOResult <> 0 Then Error (2);
  End;

  GetTime (H,M,S,Hund);
  TimeUsed := ((H * 3600) + (M * 60) + S) - TimeUsed;

  WriteLn;
  WriteLn ('Infected files : ', NumOfVirF);
  WriteLn ('Repaired files : ', NumOfVirR);
  WriteLn ('Files checked  : ', NumOfFile);
  If TimeUsed <> 0 Then Begin
    WriteLn ('Files/second   : ', (NumOfFile/TimeUsed):0:2);
    WriteLn ('Timed used     : ', TimeUsed DIV 60,' Min ', (TimeUsed - (TimeUsed DIV 60 * 60)):0,' Sec.');
  End;
  WriteLn;

  If ESC Then
    Write ('Terminated by user !')
  Else
    Write ('All files done !');

  Window (1, 1, 80, 25);
  GotoXY (1, 24);
End;

Procedure UpcaseStr (Var Str : String);
Var
  Ct : Byte;

Begin
  For Ct := 1 to Length (Str) Do
    Str[Ct] := Upcase(Str[Ct]);
End;

Procedure ChkParam;
Var
  Ct         : Byte;
  MyParamStr : String;

Begin
  ESC        := False;
  DoSub      := False;
  Beep       := False;
  NoClean    := False;
  Debug      := False;
  Prompt     := False;
  MyParamStr := '';
  OldDir     := '';
  NumOfFile  := 0;
  NumOfVirF  := 0;
  NumOfVirR  := 0;

  If ParamCount < 1 Then WriteHelpScr;

  If POS ('/',ParamStr(1)) <> 0 Then WriteHelpScr;
  For Ct := 1 To ParamCount Do
    MyParamStr := MyParamStr + ParamStr(Ct) + ' ';
  UpcaseStr (MyParamStr);

  If Pos ('/B ' , MyParamStr) > 0 Then Beep    := True;
  If Pos ('/NC ', MyParamStr) > 0 Then NoClean := True;
  If Pos ('/S ' , MyParamStr) > 0 Then DoSub   := True;
  If Pos ('/D ' , MyParamStr) > 0 Then Debug   := True; {undoc param HA!}
  If Pos ('/P ' , MyParamStr) > 0 Then Prompt  := True;

  SubCt       := 0;
  Ct          := 0;
  MyPathStr   := '';
  FileNameStr := '';
                                                {Split path and filename}
  MyParamStr := ParamStr(1);                    {[path]Filename}
  UpcaseStr(MyParamStr);

  FSplit (MyParamStr, Dir, Name, Ext);

  MyPathStr   := Dir;
  If MyPathStr[Length(MyPathStr)] = ':' Then {Patch for : 'c:'}
    MyPathStr := MyPathStr + '\'
  Else
    If MyPathStr[Length(MyPathStr)] = '\' Then
      If (MyPathStr[Length(MyPathStr) - 1] <> ':') AND (Length(MyParamStr) <> 1) Then
        Delete (MyPathStr, Length(MyPathStr), 1); {Patch for : 'c:\' and patch for : 'c:\test\tmpdir\'}

  FileNameStr := Name + Ext;
  If FileNameStr = '' Then
    FileNameStr := '*.*';

  WriteLn ('Path        : ', MyPathStr);
  WriteLn ('Filename    : ', FileNameStr);
  WriteLn ('───────────────────────────────────────────────────────────────────────────────');
  GotoXY (1, 23);
  WriteLn ('───────────────────────────────────────────────────────────────────────────────');
End;

Begin
  Clrscr;
  WriteLn;
  WriteLn ('-> Nuke ',NameOfVirus,' virus v 1.3 FREEWARE anno 1995 by BUGSY & SPAWN of OBSESSiON. <-');
  WriteLn;
  ChkParam;
  FindVirus;
End.
