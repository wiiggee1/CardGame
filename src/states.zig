const std = @import("std"); 

pub const State = enum {
    MainMenu,
    Playing,
    Waiting,
    Judging,
    // CheckWinner,
    // NextRound,
};

pub const Event = enum {
    StartGame,
    ClientConnected,
    PlayedCard, 
    ReceivedCard,
    JudgeVoted, 
    GameOver, 
    NextRound,
};

const MainMenuState = struct {};
const PlayingState = struct {};
const WaitingOthersState = struct {};
const JudgingState = struct {};

const ActiveGameState = union(State) {
    /// The `Menu` state, is the first entry prompt, and when waiting for expected 
    /// players to connect. 
    MainMenu: MainMenuState,
    /// Whenever, we are in the `playing` state, we can perform game actions. 
    /// This is the state, for picking a red card during the game round. 
    Playing: PlayingState,

    /// During the `Waiting` state, we have either performed our actions for that round. 
    /// Or we are waiting for players to join the game. In other words, in this state, 
    /// we wait for other players to finish their moves (actions).
    Waiting: WaitingOthersState,

    /// The `Judging` state, is the same as playing state, but execute 
    /// voting actions instead. By picking the appropriate card among the 
    /// received ones. 
    Judging: JudgingState,
};


