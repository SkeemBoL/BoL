using System.IO;
using System.Collections.Generic;
using UnityEngine;
using HSAnthrax;

namespace HSAnthrax
{
    public class EntryPoint
    {
        public EntryPoint()
        {
            EntryPoint.Init();

        }

        public static void Init()
        {
            NintendoBot.MenuHandler.Init();
        }
    }
}