//! The `settings` module contains the `cli.zig` file that contain the `GameConfig`
//! type. But also the `Session` type that is tightly correlated and dependent on 
//! the provided values of the `GameConfig` struct. 
//! ------------------------------------
//! This module handle settings and configs related to game setup.
//! It could initialize either of the two `SessionType` : 
//!     - SessionType: Host → Managing the Server and global gamestate. 
//!     - SessionType: Client → That holds a `Player` instance. 
//! ------------------------------------

const std = @import("std"); 
const cli = @import("cli"); 

// The player related API, should be private and only exposed within the 
// settings Module via the Session type. 
const Player = @import("player.zig").Player; 
const PlayerManager = @import("player.zig").PlayerManager;

pub const GameConfig = cli.GameConfig; 

const ServerInstance = @import("network/server.zig").ServerInstance;
const ClientInstance = @import("network/client.zig").ClientInstance;

const HostSession = struct {players: ?PlayerManager, net: ServerInstance}; 
const ClientSession = struct {player: ?Player, net: ClientInstance};


pub const SessionType = enum {
    /// A `Host` SessionType would handle a container of `Player`
    /// pointers. Its responsibility is to track the global gamestate,
    /// and act as the intermediate server between the client (players).
    /// The Host is tightly coupled with the Server. 
    Host, 
    /// A `Client` is the participant `Player` that is attending the game. 
    /// The Client is coupled with the client-socket. 
    Client,

    /// As of now, the only valid cast is from GameConfig → SessionType
    pub fn try_from(value: anytype) !SessionType{
        if(@TypeOf(value) != GameConfig){
            return error.OnlyGameConfigTypeSupported;
            // @compileError("Converting to SessionType require type to be 'GameConfig', got: " ++ @typeName(@TypeOf(value))); 
        }

        const is_hosting = @field(@as(GameConfig, value), "hosting");
        if(is_hosting) return SessionType.Host else return SessionType.Client; 
    }
};

pub const Session = union(SessionType) {
    Host: HostSession, 
    Client: ClientSession,

    /// Creating a new `Host` or `Client` Session, is defined based on the 
    /// given `GameConfig`. It maps from: GameConfig → SessionType → Session
    pub fn create(config: GameConfig, allocator: std.mem.Allocator) !Session{
        const session_kind = try SessionType.try_from(config);
        switch (session_kind) {
            .Host => {
                return Session{.Host = HostSession{
                    .players = PlayerManager.init(allocator), .net = ServerInstance{.id = 1}
                }}; 
            },
            .Client => {
                const id = config.port.?; 
                const name = config.id.?;
                return Session{.Client = ClientSession{
                    .player = Player.new(id, name, allocator),
                    .net = ClientInstance{},
                }}; 
            },
        }
    }

    pub fn get_sessiontype(self: Session) SessionType {
        switch (self) {
            .Host => return SessionType.Host,
            .Client => return SessionType.Client,
        }
    }
        
}; 

