using System;
using UnityEngine;

namespace API
{
    public class Utils
    {
        /* void Utils.FindGame(GameType gameType,  MissionId missionId, [optional]long deckId, [optional] long aiDeckId)
         * Finds Game
         */
        public static void FindGame(GameType gameType, MissionId missionId, long deckId = 0, long aiDeckId = 0)
        {
            GameMgr.Get().FindGame((PegasusShared.GameType)gameType, (int)missionId, deckId, aiDeckId);
            GameMgr.Get().UpdatePresence();

        }
    }
}
