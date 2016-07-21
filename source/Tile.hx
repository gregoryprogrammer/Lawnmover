package;

import flixel.FlxSprite;
import Config.Config;

enum TileType
{
        WALL;
        GRASS;
        CUT;
        EMPTY;
}

class Tile extends FlxSprite
{
        @:isVar public var type(default,set):TileType;

        override public function new():Void
        {
                super();
                set_type(EMPTY);
        }

        public function set_type(_type:TileType):TileType
        {
                // TODO random grass tiles
                // TODO ice

                this.type = _type;
                switch (this.type) {
                case EMPTY: loadGraphic("assets/images/empty.png");
                case WALL: loadGraphic("assets/images/wall.png");
                case GRASS: loadGraphic("assets/images/grass.png");
                case CUT: loadGraphic("assets/images/cut.png");
                }

                return this.type;
        }

        public function cycle():Void
        {
                switch (type) {
                case EMPTY: type = WALL;
                case WALL: type = GRASS;
                case GRASS: type = CUT;
                case CUT: type = EMPTY;
                }
        }
}
