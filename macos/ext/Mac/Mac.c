/* Generated automatically by WriteMacInit */

#include "INTERN.h"
#include "perl.h"

void boot_Mac()
{
    dXSUB_SYS;
    char *file = __FILE__;
    {   extern void boot_Mac__AppleEvents _((CV* cv));
        newXS("Mac::AppleEvents::bootstrap", boot_Mac__AppleEvents, file);
    }
    {   extern void boot_Mac__Components _((CV* cv));
        newXS("Mac::Components::bootstrap", boot_Mac__Components, file);
    }
    {   extern void boot_Mac__Controls _((CV* cv));
        newXS("Mac::Controls::bootstrap", boot_Mac__Controls, file);
    }
    {   extern void boot_Mac__Dialogs _((CV* cv));
        newXS("Mac::Dialogs::bootstrap", boot_Mac__Dialogs, file);
    }
    {   extern void boot_Mac__Events _((CV* cv));
        newXS("Mac::Events::bootstrap", boot_Mac__Events, file);
    }
    {   extern void boot_Mac__Files _((CV* cv));
        newXS("Mac::Files::bootstrap", boot_Mac__Files, file);
    }
    {   extern void boot_Mac__Fonts _((CV* cv));
        newXS("Mac::Fonts::bootstrap", boot_Mac__Fonts, file);
    }
    {   extern void boot_Mac__Gestalt _((CV* cv));
        newXS("Mac::Gestalt::bootstrap", boot_Mac__Gestalt, file);
    }
    {   extern void boot_Mac__InternetConfig _((CV* cv));
        newXS("Mac::InternetConfig::bootstrap", boot_Mac__InternetConfig, file);
    }
    {   extern void boot_Mac__Lists _((CV* cv));
        newXS("Mac::Lists::bootstrap", boot_Mac__Lists, file);
    }
    {   extern void boot_Mac__Memory _((CV* cv));
        newXS("Mac::Memory::bootstrap", boot_Mac__Memory, file);
    }
    {   extern void boot_Mac__Menus _((CV* cv));
        newXS("Mac::Menus::bootstrap", boot_Mac__Menus, file);
    }
    {   extern void boot_Mac__MoreFiles _((CV* cv));
        newXS("Mac::MoreFiles::bootstrap", boot_Mac__MoreFiles, file);
    }
    {   extern void boot_Mac__Movies _((CV* cv));
        newXS("Mac::Movies::bootstrap", boot_Mac__Movies, file);
    }
    {   extern void boot_Mac__OSA _((CV* cv));
        newXS("Mac::OSA::bootstrap", boot_Mac__OSA, file);
    }
    {   extern void boot_Mac__Processes _((CV* cv));
        newXS("Mac::Processes::bootstrap", boot_Mac__Processes, file);
    }
    {   extern void boot_Mac__QDOffscreen _((CV* cv));
        newXS("Mac::QDOffscreen::bootstrap", boot_Mac__QDOffscreen, file);
    }
    {   extern void boot_Mac__QuickDraw _((CV* cv));
        newXS("Mac::QuickDraw::bootstrap", boot_Mac__QuickDraw, file);
    }
    {   extern void boot_Mac__QuickTimeVR _((CV* cv));
        newXS("Mac::QuickTimeVR::bootstrap", boot_Mac__QuickTimeVR, file);
    }
    {   extern void boot_Mac__Resources _((CV* cv));
        newXS("Mac::Resources::bootstrap", boot_Mac__Resources, file);
    }
    {   extern void boot_Mac__Sound _((CV* cv));
        newXS("Mac::Sound::bootstrap", boot_Mac__Sound, file);
    }
    {   extern void boot_Mac__Speech _((CV* cv));
        newXS("Mac::Speech::bootstrap", boot_Mac__Speech, file);
    }
    {   extern void boot_Mac__SpeechRecognition _((CV* cv));
        newXS("Mac::SpeechRecognition::bootstrap", boot_Mac__SpeechRecognition, file);
    }
    {   extern void boot_Mac__StandardFile _((CV* cv));
        newXS("Mac::StandardFile::bootstrap", boot_Mac__StandardFile, file);
    }
    {   extern void boot_Mac__TextEdit _((CV* cv));
        newXS("Mac::TextEdit::bootstrap", boot_Mac__TextEdit, file);
    }
    {   extern void boot_Mac__Types _((CV* cv));
        newXS("Mac::Types::bootstrap", boot_Mac__Types, file);
    }
    {   extern void boot_Mac__Windows _((CV* cv));
        newXS("Mac::Windows::bootstrap", boot_Mac__Windows, file);
    }
}
