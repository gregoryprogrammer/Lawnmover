package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import Config.Config;
import Tile.TileType;

typedef TilePosition = {
        var x:Int;
        var y:Int;
}

enum Direction {
        NORTH;
        EAST;
        SOUTH;
        WEST;
}

enum MoverAction {
        PASS;
        GO;
        TURN_LEFT;
        TURN_RIGHT;
        CUT;
}

typedef Mover = {
        var sprite:FlxSprite;
        var position:TilePosition;
        var direction:Direction;
}

enum Comparison
{
        MATCH;
        DISMATCH;
}

class Pattern extends FlxGroup
{
        public var position(default, set):FlxPoint;

        private var m_width:Int;
        private var m_height:Int;
        private var m_tiles:Array<Tile>;

        private var m_mover:Mover;
        public var mover_freeze:Bool = true;
        public var edit_mode(default, set):Bool = false;

        static public function match(_area_master:Array<TileType>, _area_slave:Array<TileType>):Comparison
        {
                var length_master = _area_master.length;
                var length_slave = _area_slave.length;

                // master pattern is smaller than slave -> does not match
                if (length_master < length_master) return DISMATCH;

                // get the sum of all empty tiles to check if pattern is empty
                // FIXME do it in a different place
                var sum = function(num, total) { return total += num; }
                var num_empty = [for (i in 0..._area_slave.length) if (_area_slave[i] == EMPTY) 1 else 0 ];
                var sum_empty = Lambda.fold(num_empty, sum, 0);

                // array is filled with empties -> does not match to anything
                if (sum_empty == _area_slave.length) return DISMATCH;

                for (i in 0..._area_slave.length) {
                        var type_master = _area_master[i];
                        var type_slave = _area_slave[i];

                        // one tile is different -> pattern does not match
                        if (type_slave != EMPTY && type_slave != type_master) return DISMATCH;
                }

                return MATCH;
        }

        public function new(_width:Int, _height:Int, ?_position:FlxPoint):Void
        {
                super();
                m_width = _width;
                m_height = _height;

                var TILES = m_width * m_height;
                m_tiles = new Array<Tile>();

                for (i in 0...TILES) {
                        var tile = new Tile();
                        m_tiles.push(tile);
                        add(tile);
                }

                // lawnmover
                m_mover = {sprite: new FlxSprite(), position: {x: 0, y: 0}, direction: NORTH};
                m_mover.sprite.loadGraphic("assets/images/mover.png");
                add(m_mover.sprite);

                // default position
                // FIXME get rid of this (how?)
                if (_position == null) _position = new FlxPoint(0, 0);
                this.position = _position;
        }

        public function set_edit_mode(_edit_mode:Bool):Bool
        {
                this.edit_mode = _edit_mode;
                return this.edit_mode;
        }

        public function reset():Void
        {
                // reset tiles -> all empty
                for (tile in m_tiles) {
                        tile.set_type(EMPTY);
                }
        }

        override public function update(_elapsed:Float):Void
        {
                super.update(_elapsed);

                // draw mover sprite according to its tile position
                m_mover.sprite.x = position.x + m_mover.position.x * Config.TILE_SIZE;
                m_mover.sprite.y = position.y + m_mover.position.y * Config.TILE_SIZE;

                // set mover angle according to its direction
                switch (m_mover.direction) {
                case NORTH: m_mover.sprite.angle = 0;
                case EAST:  m_mover.sprite.angle = 90;
                case SOUTH: m_mover.sprite.angle = 180;
                case WEST:  m_mover.sprite.angle = 270;
                }

                if (edit_mode) {
                        if (FlxG.mouse.justPressed && is_mouse_in_field()) {

                                // FIXME to function
                                var tile_pos = mouse_to_tile_pos();
                                var tile = get_tile(tile_pos);
                                if (tile != null) tile.cycle();

                        } else if (FlxG.mouse.justPressedRight && is_mouse_in_field()) {

                                if (!mover_freeze) mover_user_control();

                        }
                }
        }

        // should be enabled in playfield edit mode
        // allows to place and rotate mover with mouse
        function mover_user_control():Void
        {
                // FIXME to function
                var mouse_tile = mouse_to_tile_pos();
                //trace("tile_pos = " + mouse_tile + "   m_mover.position = " + m_mover.position);

                var already_in_place = mouse_tile.x == m_mover.position.x && mouse_tile.y == m_mover.position.y;

                if (already_in_place) {
                        rotate_mover_cw();
                } else {
                        move_mover_to(mouse_tile);
                }
        }

        // check if mouse pointer hovers pattern field
        private function is_mouse_in_field():Bool
        {
                var mx = FlxG.mouse.x;
                var my = FlxG.mouse.y;

                var mx_in = position.x < mx && mx < position.x + m_width * Config.TILE_SIZE;
                var my_in = position.y < my && my < position.y + m_height * Config.TILE_SIZE;

                return mx_in && my_in;
        }

        // convert mouse screen coordinates to local tile position in matrix field
        private function mouse_to_tile_pos():TilePosition
        {
                var mx = FlxG.mouse.x - position.x;
                var my = FlxG.mouse.y - position.y;

                mx /= Config.TILE_SIZE;
                my /= Config.TILE_SIZE;

                return {x: Std.int(mx), y: Std.int(my)};
        }

        public function set_tiles(tiles:Array<Tile>):Void
        {
            m_tiles = tiles;
        }

        public function get_tiles():Array<Tile>
        {
            return m_tiles;
        }

        public function get_tile(_position:TilePosition):Tile
        {
                // TODO check
                // FIXME nice check

                if (!in_range(_position)) return null;

                var index = _position.x + _position.y * m_width;
                return m_tiles[index];
        }

        public function set_position(_position:FlxPoint):FlxPoint
        {
                this.position = _position;

                var TILES = m_width * m_height;

                for (i in 0...TILES) {
                        var tile = m_tiles[i];

                        tile.x = _position.x + (i % m_width) * Config.TILE_SIZE;
                        tile.y = _position.y + Std.int(i / m_width) * Config.TILE_SIZE;
                }

                return this.position;
        }

        public function load_sample_lawn():Void
        {
                // TODO from json
                var TILES = m_width * m_height;
                for (i in 0...TILES) {
                        if      (i % m_width == 0) m_tiles[i].type = WALL;
                        else if (i % m_width == m_width - 1) m_tiles[i].type = WALL;
                        else if (i < m_width) m_tiles[i].type = WALL;
                        else if (i >= TILES - m_width) m_tiles[i].type = WALL;
                        else m_tiles[i].type = GRASS;
                }
                move_mover_to({x:1, y:m_height - 2});
                m_mover.direction = EAST;
        }

        public function load_lawn(_width:Int, _height:Int, _data:Array<Int>):Void
        {
                var TILES = _width * _height;

                // set all tiles in pattern to empty
                for (i in 0...(m_width * m_height)) {
                        var tile = _data[i];
                        m_tiles[i].type = EMPTY;
                }

                for (y in 0..._height) {
                        for (x in 0..._width) {
                                var src = y * _width + x;
                                var tile_id = _data[src];

                                var dst = y * m_width + x;

                                switch (tile_id) {
                                case 1: m_tiles[dst].type = WALL;
                                case 2: m_tiles[dst].type = GRASS;
                                case 3: m_tiles[dst].type = CUT;
                                }

                        }
                }

                // TODO find first GRASS and place lawnmover there
                for (i in 0...(m_width * m_height)) {

                        if (m_tiles[i].type != GRASS) continue;

                        var x = i % m_width;
                        var y = Std.int(i / m_width);
                        move_mover_to({x:x, y:y});
                        break;
                }

                m_mover.direction = EAST;
        }

        function in_range(_position:TilePosition):Bool
        {
                var x_in_range = ((0 <= _position.x) && (_position.x < m_width));
                var y_in_range = ((0 <= _position.y) && (_position.y < m_height));

                if (!x_in_range || !y_in_range) return false;

                return true;
        }

        public function move_mover_to(_position:TilePosition):Void
        {
                if (in_range(_position)) {
                        m_mover.position = _position;
                        //trace("MOVER MOVE TO " + _position);
                } else {
                        // TODO sound or something
                }
        }

        public function mover_action(_action:MoverAction):Void
        {

                switch (_action) {
                case GO:
                        var pos:TilePosition = {x: m_mover.position.x, y: m_mover.position.y};
                        var movement:TilePosition;

                        switch (m_mover.direction) {
                        case NORTH: movement = {x:  0, y: -1};
                        case EAST:  movement = {x:  1, y:  0};
                        case SOUTH: movement = {x:  0, y:  1};
                        case WEST:  movement = {x: -1, y:  0};
                        }

                        pos.x += movement.x;
                        pos.y += movement.y;

                        move_mover_to(pos);

                case TURN_LEFT:
                        trace("TURN LEFT");
                        rotate_mover_ccw();

                case TURN_RIGHT:
                        trace("TURN RIGHT");
                        rotate_mover_cw();
                case CUT:
                        trace("CUT");
                        var tile = get_tile(m_mover.position);
                        if (tile != null && tile.type == GRASS) {
                                tile.set_type(CUT);
                        }
                case PASS: var a = 5;
                }
        }

        private function rotate_mover_cw():Void
        {
                switch (m_mover.direction) {
                case NORTH: m_mover.direction = EAST;
                case EAST: m_mover.direction = SOUTH;
                case SOUTH: m_mover.direction = WEST;
                case WEST: m_mover.direction = NORTH;
                }
        }

        private function rotate_mover_ccw():Void
        {
                switch (m_mover.direction) {
                case NORTH: m_mover.direction = WEST;
                case EAST: m_mover.direction = NORTH;
                case SOUTH: m_mover.direction = EAST;
                case WEST: m_mover.direction = SOUTH;
                }
        }

        function tiles_area(_tiles:Array<Tile>):Array<TileType>
        {
                var area = new Array<TileType>();
                for (tile in _tiles) {
                        if (tile == null) {
                                area.push(EMPTY);
                        } else {
                                area.push(tile.type);
                        }
                }
                return area;
        }

        public function mover_area():Array<TileType>
        {
                var pos = m_mover.position;

                var pos0:TilePosition = {x: pos.x - 1, y: pos.y - 1};
                var pos1:TilePosition = {x: pos.x - 0, y: pos.y - 1};
                var pos2:TilePosition = {x: pos.x + 1, y: pos.y - 1};

                var pos3:TilePosition = {x: pos.x - 1, y: pos.y + 0};
                var pos4:TilePosition = {x: pos.x - 0, y: pos.y + 0};
                var pos5:TilePosition = {x: pos.x + 1, y: pos.y + 0};

                var pos6:TilePosition = {x: pos.x - 1, y: pos.y + 1};
                var pos7:TilePosition = {x: pos.x - 0, y: pos.y + 1};
                var pos8:TilePosition = {x: pos.x + 1, y: pos.y + 1};

                // tiles
                var t0 = get_tile(pos0);
                var t1 = get_tile(pos1);
                var t2 = get_tile(pos2);
                var t3 = get_tile(pos3);
                var t4 = get_tile(pos4);
                var t5 = get_tile(pos5);
                var t6 = get_tile(pos6);
                var t7 = get_tile(pos7);
                var t8 = get_tile(pos8);

                var tiles:Array<Tile>;

                switch (m_mover.direction) {
                        case NORTH: tiles = [t0, t1, t2, t3, t4, t5, t6, t7, t8];
                        case EAST:  tiles = [t2, t5, t8, t1, t4, t7, t0, t3, t6];
                        case SOUTH: tiles = [t8, t7, t6, t5, t4, t3, t2, t1, t0];
                        case WEST:  tiles = [t6, t3, t0, t7, t4, t1, t8, t5, t2];
                }

                return tiles_area(tiles);
        }
}
