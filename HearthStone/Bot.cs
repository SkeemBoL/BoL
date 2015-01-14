using UnityEngine;

namespace NintendoBot
{
        public class Bot : MonoBehaviour
        {
            bool starting = false;
            public static void Init()
            {
                SceneMgr.Get().gameObject.AddComponent<Bot>();
            }
            private void Awake()
            {
                Object.DontDestroyOnLoad((Object)this);
            }

            private void Update()
            {
                SceneMgr.Mode GameMode = SceneMgr.Get().GetMode();
                ManageModes(GameMode);
            }
            private void ManageModes(SceneMgr.Mode Mode)
            {
                switch(Mode)
                {
                        
                   case SceneMgr.Mode.CREDITS:
                        // Enter MainMenu
                        Graphics.AddInfoMsg("Set Next Mode To Menu");
                        SceneMgr.Get().SetNextMode(SceneMgr.Mode.HUB);
                        break;
                    case SceneMgr.Mode.LOGIN:
                        if (WelcomeQuests.Get() != null)
                        {
                            // Releases Quests
                            Graphics.AddInfoMsg("Released Quests");
                            WelcomeQuests.Get().m_clickCatcher.TriggerRelease();
                        }
                        break;
                    case SceneMgr.Mode.HUB:
                        //Graphics.AddInfoMsg("Seting Adventure Mode");
                        //SceneMgr.Get().SetNextMode(SceneMgr.Mode.ADVENTURE);
                        break;
                    case SceneMgr.Mode.TOURNAMENT:
                        if (!starting && !SceneMgr.Get().IsInGame())
                        {
                            Graphics.AddInfoMsg("Starting Game");
                            Game.FindGame(PegasusShared.GameType.GT_UNRANKED, (int)MissionId.PRACTICE_EXPERT_MAGE, DeckPickerTrayDisplay.Get().GetSelectedDeckID());
                            starting = true;
                        }
                        break;
                    case SceneMgr.Mode.ADVENTURE:
                        Graphics.AddInfoMsg("Starting Game");
                        // Finds Game
                        GameMgr.Get().FindGame(PegasusShared.GameType.GT_VS_AI, (int)MissionId.PRACTICE_EXPERT_MAGE, DeckPickerTrayDisplay.Get().GetSelectedDeckID());
                        // Updates Presence
                        GameMgr.Get().UpdatePresence();
                        break;
                    default:
                        Graphics.AddErrorMsg("Cant Find Mode:" + Mode);
                        break;

                }
            }
        }
    }
