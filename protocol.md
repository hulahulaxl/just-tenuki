# Just Tenuki - Binary WebSocket Protocol (v1)

Because this engine handles massive amounts of KataGo analysis strings every second, we use a custom, ultra-lightweight binary protocol to save bandwidth and drastically reduce battery drain on mobile clients.

## Philosophy
- **Endianness:** All integers (2-byte, 4-byte) are sent in **Big-Endian** (Network Byte Order).
- **Strings:** All strings (like Query IDs) are UTF-8 encoded, prefixed by a 2-byte unsigned integer `length`.
- **Coordinates:** All Go board coordinates are sent as 1-byte flat integers `[0-360]`. (e.g. `(0, 0)` is `0`, `(18, 18)` is `360`).

---

## 1. Client to Server: Analyze Request `(OpCode 0x01)`
When the Flutter app wants KataGo to evaluate the board, it sends this packet.

| Offset | Type | Name | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `uint8` | **OpCode** | Always `0x01` (Analyze Request) |
| `0x01` | `uint16`| **Id Length** | Length of the Query ID string |
| `0x03` | `string`| **Query ID** | UTF-8 String (e.g., "query_123") |
| `0x03+L` | `uint8` | **Board Size**| `19` (or `13`, `9`) |
| `+1` | `uint8` | **Rules** | `0` = Japanese, `1` = Chinese, `2` = Tromp-Taylor |
| `+1` | `uint8` | **Komi** | `65` (Divide by 10. `65` = 6.5) |
| `+1` | `uint16`| **Setup Count** | Number of initial setup stones |
| `+2` | `[...]` | **Setup Stones**| Array of `[Player(uint8), Index(uint16)]` |
| `+N` | `uint16`| **Move Count** | Total chronological moves in the game path |
| `+2` | `[...]` | **Moves** | Array of `[Player(uint8), Index(uint16)]` |

---

## 2. Server to Client: Analysis Update `(OpCode 0x02)`
KataGo streams multiple updates for a single request. The Server packs them into this byte array and blasts them to the client.

| Offset | Type | Name | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `uint8` | **OpCode** | Always `0x02` (Analysis Response) |
| `0x01` | `uint16`| **Id Length** | Length of the Query ID string |
| `0x03` | `string`| **Query ID** | Must match the ID sent by the client |
| `0x03+L` | `float32`| **Winrate** | `0.0` to `1.0` (Black's win probability) |
| `+4` | `float32`| **ScoreLead** | e.g. `12.5` (Black is winning by 12.5 points) |
| `+4` | `uint8` | **Move Options**| Number of Principal Variations (PVs) attached |
| `+1` | `[...]` | **Move Blocks** | See below |

#### Move Block Structure
For every move option returned, we append this block:
| Offset | Type | Name | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `uint16`| **Move Index** | The 1D flat index of this move on the board |
| `0x02` | `float32`| **Winrate** | Winrate if this move is played |
| `0x06` | `uint32`| **Visits** | Number of neural net evaluations for this branch |
| `0x0A` | `uint8` | **PV Length** | Number of stones in the predicted variation |
| `0x0B` | `[...]` | **PV Indices** | Array of `uint16` move indices forming the variation |
