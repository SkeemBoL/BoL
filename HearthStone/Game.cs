using System;

namespace NintendoBot
{
    class Game
    {   
        // Delay Stufff
        private static DateTime delayStart = DateTime.Now;
        private static long delayLenght = 0;
        public static bool wait = false;

        public static void Delay(long msec)
        {
            delayStart = DateTime.Now;
            delayLenght = msec;
        }

        public static void DelayUpdate()
        {
            DateTime currTime = DateTime.Now;
            TimeSpan timeSince = currTime - delayStart;
            if (timeSince.TotalMilliseconds < delayLenght)
            {
                wait = true;
            }
            else
            {
                wait = false;
            }
        }

        // Find Game
        public static void FindGame(PegasusShared.GameType gameType, int missionId, long deckId = 0, long aiDeckId = 0)
        {
            GameMgr.Get().FindGame(gameType, missionId, deckId, aiDeckId);
            GameMgr.Get().UpdatePresence();
        }
    }
}
