package;

import Tile;
import Instruction;

class Reg
{
        public static var level_file = null;
        public static var level = null;

        public static var saved_program:Map<String, Array<Action>> = new Map<String, Array<Action>>();
        public static var saved_pattern:Map<String, TileType> = new Map<String, TileType>();
}
