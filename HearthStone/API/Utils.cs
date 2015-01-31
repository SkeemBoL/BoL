using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace API
{
    public class Utils
    {
        /* List Utils.GetDeckList()
         * returns list of all available decks
         */
        public static List<CollectionDeck> GetDeckList()
        {
            List<CollectionDeck> deckList = new List<CollectionDeck>();
            foreach (KeyValuePair<long, CollectionDeck> deck in CollectionManager.Get().GetDecks())
            {
                deckList.Add(CollectionManager.Get().GetDeck(deck.Key));
            }
            return deckList;
        }

        /* long Utils.GetSelectedDeckID()
         * returns the ID of the deck currently selected
         */
        public static long GetSelectedDeckID()
        {
            return DeckPickerTrayDisplay.Get().GetSelectedDeckID();
        }

        /* MissionId Utils.RandomMission(bool expert)
         * returns a random mission id
         */

        public static MissionId RandomMission(bool expert)
        {
            System.Random random = new System.Random();
            ReadOnlyCollection<MissionId> AI_Normal =
                new ReadOnlyCollection<MissionId>(new[]
            {
                MissionId.PRACTICE_NORMAL_MAGE,   MissionId.PRACTICE_NORMAL_WARLOCK,
                MissionId.PRACTICE_NORMAL_HUNTER, MissionId.PRACTICE_NORMAL_ROGUE,
                MissionId.PRACTICE_NORMAL_PRIEST, MissionId.PRACTICE_NORMAL_WARRIOR,
                MissionId.PRACTICE_NORMAL_DRUID,  MissionId.PRACTICE_NORMAL_PALADIN,
                MissionId.PRACTICE_NORMAL_SHAMAN
            });

            ReadOnlyCollection<MissionId> AI_Expert =
                new ReadOnlyCollection<MissionId>(new[]
            {
                MissionId.PRACTICE_EXPERT_MAGE,   MissionId.PRACTICE_EXPERT_WARLOCK,
                MissionId.PRACTICE_EXPERT_HUNTER, MissionId.PRACTICE_EXPERT_ROGUE,
                MissionId.PRACTICE_EXPERT_PRIEST, MissionId.PRACTICE_EXPERT_WARRIOR,
                MissionId.PRACTICE_EXPERT_DRUID,  MissionId.PRACTICE_EXPERT_PALADIN,
                MissionId.PRACTICE_EXPERT_SHAMAN
            });
            ReadOnlyCollection<MissionId> AI_Selected = (expert) ? AI_Expert : AI_Normal;
            int index = random.Next(AI_Selected.Count);
            return AI_Selected[index];
        }

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
