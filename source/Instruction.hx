package;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;

import Config.Config;
import Pattern.MowerAction;



enum Action
{
        PASS;
        GO;
        TURN_LEFT;
        TURN_RIGHT;
        CUT;
        JUMP (i:Int);
}

class Instruction extends FlxGroup
{
        public static inline var WIDTH = 176;
        /*
         * 176 =
         *       8  - FRAME
         *       16 - ID
         *       48 - PATTERN
         *       16 - GAP
         *       80 - ACTION
         *       8  - FRAME
         */

        public static inline var FRAME = 4;
        public static inline var HEIGHT = Config.TILE_SIZE * 3 + FRAME * 2;
        public static inline var NUM = 20;

        public static inline var ACTION_WIDTH = 80;
        public static inline var ACTION_HEIGHT = 20;


        private var m_background:FlxSprite;
        private var m_good_background:FlxSprite;
        private var m_bad_background:FlxSprite;


        public var pattern:Pattern;

        public var highlight:Bool = false;
        public var edit_mode(default, set):Bool = true;

        private var m_action_true:FlxButton;
        private var m_action_false:FlxButton;

        private var m_true_choices:Choices;
        private var m_false_choices:Choices;

        public var action_true(default, set):Action = PASS;
        public var action_false(default, set):Action = PASS;
        public var in_choice(get, null):Bool = false;

        public var x:Int = 0;
        public var y:Int = 0;

        public function new(_x:Int, _y:Int, _id:Int):Void
        {
                super();
                this.x = _x;
                this.y = _y;

                m_background = new FlxSprite(_x, _y);
                m_background.makeGraphic(WIDTH, HEIGHT, 0xFF222222);

                m_good_background = new FlxSprite(_x, _y);
                m_good_background.makeGraphic(WIDTH, Std.int(HEIGHT / 2), 0xFF44AA44);
                m_good_background.y = _y;  // stick to top

                m_bad_background = new FlxSprite(_x, _y);
                m_bad_background.makeGraphic(WIDTH, Std.int(HEIGHT / 2), 0xFFAA4444);
                m_bad_background.y = _y + HEIGHT - HEIGHT / 2;  // stick to bottom

                pattern = new Pattern(3, 3);
                pattern.position = new FlxPoint(x + FRAME + 16, y + FRAME);
                pattern.move_mower_to({x:1, y:1});

                // 20 = button height
                m_action_true = new FlxButton(x + FRAME + 16 + 48 + 16, y + FRAME, "ACTION", on_true_action_choice);
                m_action_false = new FlxButton(x + FRAME + 16 + 48 + 16, y + HEIGHT - FRAME - ACTION_HEIGHT, "ACTION", on_false_action_false);
                update_action_text();

                var id = StringTools.lpad("" + _id, "0", 2);
                var label_id = new FlxText(_x + FRAME, _y + FRAME, id);

                add(m_background);
                add(m_good_background);
                add(m_bad_background);
                add(pattern);
                add(m_action_true);
                add(m_action_false);
                add(label_id);
        }

        public function get_in_choice():Bool
        {
                return m_true_choices.visible || m_false_choices.visible;
        }

        public function set_edit_mode(_edit_mode):Bool
        {
                this.edit_mode = _edit_mode;

                pattern.edit_mode = _edit_mode;
                m_action_true.active = _edit_mode;
                m_action_false.active = _edit_mode;

                return this.edit_mode;
        }

        public function create_true_choices():Choices
        {
                // FIXME one choices instance for true and false
                m_true_choices = new Choices();
                m_true_choices.hide();

                m_true_choices.add_choice(0, 0, "PASS", function() { action_true = PASS; });
                m_true_choices.add_choice(0, 1, "GO", function() { action_true = GO; });
                m_true_choices.add_choice(0, 2, "TURN LEFT", function() { action_true = TURN_LEFT; });
                m_true_choices.add_choice(0, 3, "TURN RIGHT", function() { action_true = TURN_RIGHT; });
                m_true_choices.add_choice(0, 4, "CUT", function() { action_true = CUT; });

                m_true_choices.add_choice(1, 0, "JUMP 00", function() { action_true = JUMP(0); });
                m_true_choices.add_choice(1, 1, "JUMP 01", function() { action_true = JUMP(1); });
                m_true_choices.add_choice(1, 2, "JUMP 02", function() { action_true = JUMP(2); });
                m_true_choices.add_choice(1, 3, "JUMP 03", function() { action_true = JUMP(3); });

                m_true_choices.add_choice(2, 0, "JUMP 04", function() { action_true = JUMP(4); });
                m_true_choices.add_choice(2, 1, "JUMP 05", function() { action_true = JUMP(5); });
                m_true_choices.add_choice(2, 2, "JUMP 06", function() { action_true = JUMP(6); });
                m_true_choices.add_choice(2, 3, "JUMP 07", function() { action_true = JUMP(7); });

                m_true_choices.add_choice(3, 0, "JUMP 08", function() { action_true = JUMP(8); });
                m_true_choices.add_choice(3, 1, "JUMP 09", function() { action_true = JUMP(9); });
                m_true_choices.add_choice(3, 2, "JUMP 10", function() { action_true = JUMP(10); });
                m_true_choices.add_choice(3, 3, "JUMP 11", function() { action_true = JUMP(11); });

                m_true_choices.add_choice(4, 0, "JUMP 12", function() { action_true = JUMP(12); });
                m_true_choices.add_choice(4, 1, "JUMP 13", function() { action_true = JUMP(13); });
                m_true_choices.add_choice(4, 2, "JUMP 14", function() { action_true = JUMP(14); });
                m_true_choices.add_choice(4, 3, "JUMP 15", function() { action_true = JUMP(15); });

                m_true_choices.add_choice(5, 0, "JUMP 16", function() { action_true = JUMP(16); });
                m_true_choices.add_choice(5, 1, "JUMP 17", function() { action_true = JUMP(17); });
                m_true_choices.add_choice(5, 2, "JUMP 18", function() { action_true = JUMP(18); });
                m_true_choices.add_choice(5, 3, "JUMP 19", function() { action_true = JUMP(19); });

                m_true_choices.highlight(0, 0);
                // FIXME
                // update_background in choices.show if dirty == true
                // dirty = true  <- add_choice
                // dirty = false <- pdate_background
                m_true_choices.update_background();

                return m_true_choices;
        }

        public function create_false_choices():Choices
        {
                m_false_choices = new Choices();
                m_false_choices.hide();

                m_false_choices.add_choice(0, 0, "PASS", function() { action_false = PASS; });
                m_false_choices.add_choice(0, 1, "GO", function() { action_false = GO; });
                m_false_choices.add_choice(0, 2, "TURN LEFT", function() { action_false = TURN_LEFT; });
                m_false_choices.add_choice(0, 3, "TURN RIGHT", function() { action_false = TURN_RIGHT; });
                m_false_choices.add_choice(0, 4, "CUT", function() { action_false = CUT; });

                m_false_choices.add_choice(1, 0, "JUMP 00", function() { action_false = JUMP(0); });
                m_false_choices.add_choice(1, 1, "JUMP 01", function() { action_false = JUMP(1); });
                m_false_choices.add_choice(1, 2, "JUMP 02", function() { action_false = JUMP(2); });
                m_false_choices.add_choice(1, 3, "JUMP 03", function() { action_false = JUMP(3); });

                m_false_choices.add_choice(2, 0, "JUMP 04", function() { action_false = JUMP(4); });
                m_false_choices.add_choice(2, 1, "JUMP 05", function() { action_false = JUMP(5); });
                m_false_choices.add_choice(2, 2, "JUMP 06", function() { action_false = JUMP(6); });
                m_false_choices.add_choice(2, 3, "JUMP 07", function() { action_false = JUMP(7); });

                m_false_choices.add_choice(3, 0, "JUMP 08", function() { action_false = JUMP(8); });
                m_false_choices.add_choice(3, 1, "JUMP 09", function() { action_false = JUMP(9); });
                m_false_choices.add_choice(3, 2, "JUMP 10", function() { action_false = JUMP(10); });
                m_false_choices.add_choice(3, 3, "JUMP 11", function() { action_false = JUMP(11); });

                m_false_choices.add_choice(4, 0, "JUMP 12", function() { action_false = JUMP(12); });
                m_false_choices.add_choice(4, 1, "JUMP 13", function() { action_false = JUMP(13); });
                m_false_choices.add_choice(4, 2, "JUMP 14", function() { action_false = JUMP(14); });
                m_false_choices.add_choice(4, 3, "JUMP 15", function() { action_false = JUMP(15); });

                m_false_choices.add_choice(5, 0, "JUMP 16", function() { action_false = JUMP(16); });
                m_false_choices.add_choice(5, 1, "JUMP 17", function() { action_false = JUMP(17); });
                m_false_choices.add_choice(5, 2, "JUMP 18", function() { action_false = JUMP(18); });
                m_false_choices.add_choice(5, 3, "JUMP 19", function() { action_false = JUMP(19); });

                m_false_choices.highlight(0, 0);

                m_false_choices.update_background();

                return m_false_choices;
        }

        public function set_action_true(_action:Action):Action
        {
                this.action_true = _action;
                update_action_text();
                return this.action_true;
        }

        public function set_action_false(_action:Action):Action
        {
                this.action_false = _action;
                update_action_text();
                return this.action_false;
        }

        override public function update(_elapsed:Float):Void
        {
                super.update(_elapsed);

                if (!highlight) {
                        m_bad_background.visible = false;
                        m_good_background.visible = false;
                }
        }

        public function reset():Void
        {
                pattern.reset();
                m_bad_background.visible = false;
                m_good_background.visible = false;

                // 2. true action -> PASS
                action_true = PASS;

                // 3. false action -> PASS
                action_false = PASS;

                update_action_text();
        }

        function update_action_text():Void
        {
                switch (action_true) {
                case PASS: m_action_true.label.text = "PASS";
                case GO: m_action_true.label.text = "GO";
                case TURN_LEFT: m_action_true.label.text = "TURN LEFT";
                case TURN_RIGHT: m_action_true.label.text = "TURN RIGHT";
                case CUT: m_action_true.label.text = "CUT GRASS";
                case JUMP(i): m_action_true.label.text = "JUMP_" + StringTools.lpad("" + i, "0", 2);
                }

                switch (action_false) {
                case PASS: m_action_false.label.text = "PASS";
                case GO: m_action_false.label.text = "GO";
                case TURN_LEFT: m_action_false.label.text = "TURN LEFT";
                case TURN_RIGHT: m_action_false.label.text = "TURN RIGHT";
                case CUT: m_action_false.label.text = "CUT GRASS";
                case JUMP(i): m_action_false.label.text = "JUMP_" + StringTools.lpad("" + i, "0", 2);
                }
        }

        function on_true_action_choice():Void
        {
                m_true_choices.show();
        }

        function on_false_action_false():Void
        {
                m_false_choices.show();
        }

        public function highlight_good():Void
        {
                m_good_background.visible = true;
                m_bad_background.visible = false;
        }

        public function highlight_bad():Void
        {
                m_good_background.visible = false;
                m_bad_background.visible = true;
        }
}
