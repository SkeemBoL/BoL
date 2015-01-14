namespace NintendoBot
{
    class Game
    {
        public static void FindGame(PegasusShared.GameType gameType, int missionId, long deckId = 0, long aiDeckId = 0)
        {
            GameMgr.Get().FindGame(gameType, missionId, deckId, aiDeckId);
            GameMgr.Get().UpdatePresence();
        }
    }
}
