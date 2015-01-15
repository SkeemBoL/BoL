using UnityEngine;

namespace NintendoBot
{
        public class MenuHandler : MonoBehaviour
        {
            private bool starting  = false;
            private bool GameStarted = false;
            public static void Init()
            {
                SceneMgr.Get().gameObject.AddComponent<MenuHandler>();
            }
            private void Awake()
            {
                Object.DontDestroyOnLoad((Object)this);
            }
            private void Update()
            {
                Game.DelayUpdate();
                if (!Game.wait)
                {
                    SceneMgr.Mode GameMode = SceneMgr.Get().GetMode();
                    ManageModes(GameMode);
                }
                else
                {
                    Graphics.AddInfoMsg("Waiting for Delay");
                }
                Graphics.DrawText("My Health: " + GameState.Get().GetCurrentPlayer().GetHealth().ToString(), 15, 100, 100, UnityEngine.Color.red);
            }
            private void OnGUI()
            {
                
            }
            private void ManageModes(SceneMgr.Mode Mode)
            {
                switch(Mode)
                {
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
                        if (!starting)
                        {
                            Game.Delay(2000);
                            Graphics.AddInfoMsg("Starting Game");
                            Game.FindGame(PegasusShared.GameType.GT_UNRANKED, (int)MissionId.MULTIPLAYER_1v1, DeckPickerTrayDisplay.Get().GetSelectedDeckID());
                            starting = true;
                        }
                        break;
                    case SceneMgr.Mode.ADVENTURE:
                        if (!starting)
                        {
                            Game.Delay(2000);
                            Graphics.AddInfoMsg("Starting Game");
                            Game.FindGame(PegasusShared.GameType.GT_VS_AI, (int)MissionId.NAXX_ANUBREKHAN, DeckPickerTrayDisplay.Get().GetSelectedDeckID());
                            starting = true;
                        }
                        break;
                    case SceneMgr.Mode.GAMEPLAY:
                        if (!GameStarted)
                        {
                            Graphics.AddInfoMsg("Starting GameHandler");
                            GameStarted = true;
                            NintendoBot.GameHandler.Init();
                        }

                        break;
                    default:
                        Graphics.AddErrorMsg("Cant Find Mode:" + Mode);
                        break;

                }
            }
        }
    }
