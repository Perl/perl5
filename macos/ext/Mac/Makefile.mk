PERL_SRC	=	::::
MACPERL_SRC	=	:::

.INCLUDE : :::BuildRules.mk

COpt += -i :::

# Navigation:Navigation
# DCon:DCon
# SAT:SAT
# ImageCompression:ImageCompression
dirs = 	\
	err:err					\
	AppleEvents:AppleEvents			\
	Components:Components			\
	Controls:Controls			\
	Dialogs:Dialogs				\
	Events:Events				\
	Files:Files				\
	Fonts:Fonts				\
	Gestalt:Gestalt				\
	InternetConfig:InternetConfig		\
	Lists:Lists				\
	Memory:Memory				\
	Menus:Menus				\
	MoreFiles:MoreFiles			\
	Movies:Movies				\
	Notification:Notification		\
	OSA:OSA					\
	Processes:Processes			\
	QDOffscreen:QDOffscreen			\
	QuickDraw:QuickDraw			\
	QuickTimeVR:QuickTimeVR			\
	Resources:Resources			\
	Sound:Sound				\
	Speech:Speech				\
	SpeechRecognition:SpeechRecognition	\
	StandardFile:StandardFile		\
	TextEdit:TextEdit			\
	Types:Types				\
	Windows:Windows

all static dynamic install install_static install_dynamic: Obj
	For dir in $(dirs:f)
		Directory {{dir}}
		Set Echo 0
		If `Newer Makefile.PL Makefile.mk` == "Makefile.PL"
			$(MACPERL_SRC):miniperl -I$(MACPERL_SRC):lib -I$(MACPERL_SRC)::lib  Makefile.PL
		End
		BuildProgram $@
		directory ::
		Set Echo 1
	End

static install_static::  Mac.{$(MACPERL_BUILD_EXT_STATIC)}.Lib
	
Mac.68K.Lib		:	Mac.c.68K.o
	$(Lib68K) -o $@ :Obj:Mac.c.68K.o :{($dirs)}.68K.Lib
Mac.PPC.Lib		:	Mac.c.PPC.o
	$(LibPPC) -o $@ :Obj:Mac.c.PPC.o :{($dirs)}.PPC.Lib
Mac.SC.Lib		:	Mac.c.SC.o
	$(LibSC) -o $@:Obj:Mac.c.SC.o :{($dirs)}.SC.Lib
Mac.MrC.Lib		:	Mac.c.MrC.o
	$(LibMrC) -o $@ :Obj:Mac.c.MrC.o :{($dirs)}.MrC.Lib

Mac.c : Makefile.mk
	perl WriteMacInit $(dirs:f) > Mac.c

.INCLUDE : :::BulkBuildRules.mk
